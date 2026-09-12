#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/../.." && pwd)
chroma=${1:?usage: smoke-shell.sh /path/to/chroma [artifacts]}
artifacts=${2:-$(mktemp -d /tmp/lumina-shell-qa.XXXXXX)}
mkdir -p "$artifacts"
artifacts=$(realpath "$artifacts")
if [[ ${LUMINA_QA_DBUS:-0} != 1 ]]; then
    exec dbus-run-session -- env LUMINA_QA_DBUS=1 bash "$0" "$chroma" "$artifacts"
fi
export XDG_RUNTIME_DIR="$artifacts/runtime"
export XDG_CONFIG_HOME="$artifacts/config"
export XDG_STATE_HOME="$artifacts/state"
export XDG_CACHE_HOME="$artifacts/cache"
mkdir -p "$XDG_RUNTIME_DIR" "$XDG_CONFIG_HOME/lumina"
chmod 700 "$XDG_RUNTIME_DIR"
python3 - "$repo" "$XDG_CONFIG_HOME/lumina/shell.json" <<'PY'
import json,sys
from pathlib import Path
Path(sys.argv[2]).write_text(json.dumps({'background':{'wallpaperPath':sys.argv[1]+'/common/lumina-artwork/files/lumina-default.png'}}))
PY
unset WAYLAND_DISPLAY
export LANG=C.UTF-8 LC_ALL=C.UTF-8
export WLR_BACKENDS=headless WLR_HEADLESS_OUTPUTS=${LUMINA_QA_OUTPUTS:-1} WLR_LIBINPUT_NO_DEVICES=1 WLR_RENDERER=pixman
export QT_QUICK_BACKEND=software QT_QPA_PLATFORM=wayland
export LUMINA_CONTROLS_HELPER="$repo/desktop/lumina-shell/files/lumina-controls"
export LUMINA_ASSISTANT_HELPER="$repo/desktop/lumina-shell/files/lumina-assistant"
compositor_pid= shell_pid= app_pid= audio_pid=
pipewire >"$artifacts/pipewire.log" 2>&1 &
audio_pid=$!
cleanup() {
    for pid in "$app_pid" "$shell_pid" "$compositor_pid" "$audio_pid"; do
        [[ -z "$pid" ]] || kill "$pid" 2>/dev/null || true
    done
    wait 2>/dev/null || true
}
trap cleanup EXIT
"$chroma" --config "$artifacts/nonexistent.toml" >"$artifacts/chroma.log" 2>&1 &
compositor_pid=$!
for _ in {1..100}; do
    for candidate in "$XDG_RUNTIME_DIR"/wayland-*; do
        if [[ -S "$candidate" ]]; then export WAYLAND_DISPLAY=${candidate##*/}; break 2; fi
    done
    sleep 0.05
done
: "${WAYLAND_DISPLAY:?Compositor failed to start}"
export CHROMA_CONTROL_SOCKET="$XDG_RUNTIME_DIR/chroma/$WAYLAND_DISPLAY/control.sock"
for ((output=1; output<=WLR_HEADLESS_OUTPUTS; output++)); do
    wlr-randr --output "HEADLESS-$output" --custom-mode "${LUMINA_QA_MODE:-1280x800}@60Hz" --scale "${LUMINA_QA_SCALE:-1}"
done
quickshell -p "$repo/desktop/lumina-shell/shell" >"$artifacts/shell.log" 2>&1 &
shell_pid=$!
ready=0
for _ in {1..100}; do
    if ! kill -0 "$shell_pid" 2>/dev/null; then cat "$artifacts/shell.log"; exit 1; fi
    if quickshell ipc -p "$repo/desktop/lumina-shell/shell" show >"$artifacts/ipc.txt" 2>/dev/null; then ready=1; break; fi
    sleep 0.1
done
[[ $ready = 1 ]] || { cat "$artifacts/shell.log"; exit 1; }
weston-terminal >"$artifacts/terminal.log" 2>&1 &
app_pid=$!
sleep 1
notify-send --app-name='Lumina QA' 'Cassiopeia notification' 'Notification delivery through the Lumina shell'
sleep 0.2
quickshell ipc -p "$repo/desktop/lumina-shell/shell" call shell status >"$artifacts/status.json"
grim "$artifacts/desktop.png"
for panel in assistant overview launcher controls settings notifications clock; do
    quickshell ipc -p "$repo/desktop/lumina-shell/shell" call "$panel" toggle
    sleep 0.4
    grim "$artifacts/$panel.png"
    quickshell ipc -p "$repo/desktop/lumina-shell/shell" call shell close
done
kill "$shell_pid"
wait "$shell_pid" || true
shell_pid=
cp -a "$repo/desktop/lumina-shell/shell" "$artifacts/settings-fixture"
cp "$repo/desktop/tests/SettingsFixture.qml" "$artifacts/settings-fixture/shell.qml"
timeout 20 quickshell -p "$artifacts/settings-fixture" >"$artifacts/settings-actions.log" 2>&1
grep -q SETTINGS_FIXTURE_PASS "$artifacts/settings-actions.log"
LUMINA_SETTINGS_VERIFY_RELOAD=1 timeout 15 quickshell -p "$artifacts/settings-fixture" >"$artifacts/settings-reload.log" 2>&1
grep -q SETTINGS_RELOAD_PASS "$artifacts/settings-reload.log"
python3 - "$XDG_CONFIG_HOME/lumina/shell.json" <<'PYSAVED'
import json,sys
config=json.load(open(sys.argv[1]))
assert config['notifications']['dnd'] is True, config
assert config['appearance']['dark'] is False, config
assert config['bar']['showAssistant'] is False, config
PYSAVED
mkdir -p "$artifacts/action-fixture/services"
cp "$repo/desktop/tests/ChromaFixture.qml" "$artifacts/action-fixture/shell.qml"
cp "$repo/desktop/lumina-shell/shell/services/Chroma.qml" "$artifacts/action-fixture/services/Chroma.qml"
timeout 20 quickshell -p "$artifacts/action-fixture" >"$artifacts/actions.log" 2>&1
grep -q CHROMA_ACTION_FIXTURE_PASS "$artifacts/actions.log"
python3 - "$artifacts/status.json" <<'PY'
import json,sys
state=json.load(open(sys.argv[1]))
assert state['connected'],state
assert state['windows'] >= 1,state
PY
python3 - "$artifacts/shell.log" <<'PYLOG'
import re,sys
from pathlib import Path
text=open(sys.argv[1]).read()+Path(sys.argv[1]).with_name('settings-actions.log').read_text()
errors=[line for line in text.splitlines() if re.search(r'ERROR|ReferenceError|TypeError|is not a type|Cannot assign|Unable to assign|not defined',line)]
if errors: raise SystemExit('\n'.join(errors))
PYLOG
printf 'Shell integration passed: %s\n' "$artifacts"
