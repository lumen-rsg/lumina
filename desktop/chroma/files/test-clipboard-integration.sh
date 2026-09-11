#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "usage: $0 CHROMA_BINARY" >&2
    exit 2
fi

for dependency in wl-copy wl-paste timeout; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
        echo "SKIP: clipboard integration requires $dependency"
        exit 77
    fi
done

chroma_binary=$(realpath "$1")
test_root=$(mktemp -d /tmp/chroma-clipboard-test.XXXXXX)
compositor_pid=""
copy_pid=""
cleanup() {
    if [[ -n "$copy_pid" ]]; then
        kill "$copy_pid" 2>/dev/null || true
        wait "$copy_pid" 2>/dev/null || true
    fi
    if [[ -n "$compositor_pid" ]]; then
        kill "$compositor_pid" 2>/dev/null || true
        wait "$compositor_pid" 2>/dev/null || true
    fi
    if [[ -n ${test_root:-} && "$test_root" == /tmp/chroma-clipboard-test.* ]]; then
        find "$test_root" -depth -delete
    fi
}
trap cleanup EXIT INT TERM

chmod 700 "$test_root"
mkdir -p "$test_root/config"
export XDG_RUNTIME_DIR="$test_root"
export XDG_CONFIG_HOME="$test_root/config"
export WLR_BACKENDS=headless
export WLR_HEADLESS_OUTPUTS=1
export WLR_LIBINPUT_NO_DEVICES=1
export WLR_RENDERER=pixman

"$chroma_binary" --config "$test_root/missing.toml" \
    >"$test_root/compositor.log" 2>&1 &
compositor_pid=$!

socket_path=""
for _ in $(seq 1 120); do
    socket_path=$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -type s \
        -name 'wayland-*' -print -quit)
    [[ -n "$socket_path" ]] && break
    sleep 0.05
done
if [[ -z "$socket_path" ]]; then
    echo "compositor did not create a Wayland socket" >&2
    sed -n '1,200p' "$test_root/compositor.log" >&2
    exit 1
fi
export WAYLAND_DISPLAY
WAYLAND_DISPLAY=$(basename "$socket_path")

check_selection() {
    local kind=$1
    local expected=$2
    local primary=()
    if [[ "$kind" == primary ]]; then
        primary=(--primary)
    fi

    printf '%s' "$expected" | timeout 5 wl-copy --foreground \
        "${primary[@]}" >"$test_root/$kind-copy.log" 2>&1 &
    copy_pid=$!
    sleep 0.15
    local actual
    actual=$(timeout 5 wl-paste --no-newline "${primary[@]}")
    if [[ "$actual" != "$expected" ]]; then
        echo "$kind selection mismatch: expected '$expected', got '$actual'" >&2
        exit 1
    fi
    kill "$copy_pid" 2>/dev/null || true
    wait "$copy_pid" 2>/dev/null || true
    copy_pid=""
}

check_selection regular chroma-clipboard-roundtrip
check_selection primary chroma-primary-roundtrip

if grep -E 'ASSERT|AddressSanitizer|runtime error:' \
    "$test_root/compositor.log" >/dev/null; then
    sed -n '1,240p' "$test_root/compositor.log" >&2
    exit 1
fi

echo "regular and primary clipboard roundtrips passed"
