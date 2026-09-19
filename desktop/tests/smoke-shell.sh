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
export LUMINA_QA_ARTIFACTS="$artifacts"
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
compositor_pid= shell_pid= app_pid= audio_pid= media_pid=
pipewire >"$artifacts/pipewire.log" 2>&1 &
audio_pid=$!
cleanup() {
    for pid in "$app_pid" "$shell_pid" "$compositor_pid" "$audio_pid" "$media_pid"; do
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
    if quickshell ipc -p "$repo/desktop/lumina-shell/shell" call shell status >"$artifacts/ipc.txt" 2>/dev/null; then ready=1; break; fi
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
for panel in assistant overview hints launcher controls settings notifications clock; do
    quickshell ipc -p "$repo/desktop/lumina-shell/shell" call "$panel" toggle
    sleep 0.4
    grim "$artifacts/$panel.png"
    quickshell ipc -p "$repo/desktop/lumina-shell/shell" call shell close
done
kill "$shell_pid"
wait "$shell_pid" || true
shell_pid=
cp -a "$repo/desktop/lumina-shell/shell" "$artifacts/spatial-fixture"
cp "$repo/desktop/tests/SpatialFixture.qml" "$artifacts/spatial-fixture/shell.qml"
timeout 25 quickshell -p "$artifacts/spatial-fixture" >"$artifacts/spatial.log" 2>&1
grep -q SPATIAL_FIXTURE_PASS "$artifacts/spatial.log"
LUMINA_SPATIAL_RELOAD=1 timeout 10 quickshell -p "$artifacts/spatial-fixture" >"$artifacts/spatial-reload.log" 2>&1
grep -q SPATIAL_RELOAD_PASS "$artifacts/spatial-reload.log"
if [[ ${LUMINA_QA_SPATIAL_ONLY:-0} == 1 ]]; then
    if grep -E 'ERROR|ReferenceError|TypeError|Cannot assign|Unable to assign|Binding loop' "$artifacts/shell.log" "$artifacts/spatial.log" "$artifacts/spatial-reload.log"; then exit 1; fi
    echo 'Spatial shell integration passed'
    exit 0
fi
# Restore the default palette before existing settings regression fixtures.
python3 - "$XDG_CONFIG_HOME/lumina/shell.json" <<'PYCOLOR'
import json,sys
from pathlib import Path
p=Path(sys.argv[1]); data=json.loads(p.read_text()); data['appearance']['theme']='cassiopeia'; p.write_text(json.dumps(data))
PYCOLOR
cp -a "$repo/desktop/lumina-shell/shell" "$artifacts/widgets-fixture"
cp "$repo/desktop/tests/SidebarFixture.qml" "$artifacts/widgets-fixture/shell.qml"
timeout 20 quickshell -p "$artifacts/widgets-fixture" >"$artifacts/sidebar.log" 2>&1
grep -q SIDEBAR_FIXTURE_PASS "$artifacts/sidebar.log"
cp "$repo/desktop/tests/ProductivityFixture.qml" "$artifacts/widgets-fixture/shell.qml"
timeout 20 quickshell -p "$artifacts/widgets-fixture" >"$artifacts/productivity.log" 2>&1
grep -q PRODUCTIVITY_FIXTURE_PASS "$artifacts/productivity.log"
LUMINA_PRODUCTIVITY_RELOAD=1 timeout 15 quickshell -p "$artifacts/widgets-fixture" >"$artifacts/productivity-reload.log" 2>&1
grep -q PRODUCTIVITY_RELOAD_PASS "$artifacts/productivity-reload.log"
cp "$XDG_CONFIG_HOME/lumina/productivity.json" "$artifacts/productivity.json"
printf '%s' '{"tasks":"invalid"}' >"$XDG_CONFIG_HOME/lumina/productivity.json"
LUMINA_PRODUCTIVITY_CORRUPT=1 timeout 15 quickshell -p "$artifacts/widgets-fixture" >"$artifacts/productivity-corrupt.log" 2>&1
grep -q PRODUCTIVITY_CORRUPT_PASS "$artifacts/productivity-corrupt.log"
[[ $(cat "$XDG_CONFIG_HOME/lumina/productivity.json") == '{"tasks":"invalid"}' ]]
cp "$artifacts/productivity.json" "$XDG_CONFIG_HOME/lumina/productivity.json"
cp "$repo/desktop/tests/MediaFixture.qml" "$artifacts/widgets-fixture/shell.qml"
python3 "$repo/desktop/tests/fake-mpris.py" "$artifacts/media-calls.json" >"$artifacts/media-player.log" 2>&1 &
media_pid=$!
timeout 20 quickshell -p "$artifacts/widgets-fixture" >"$artifacts/media.log" 2>&1
grep -q MEDIA_FIXTURE_PASS "$artifacts/media.log"
wait "$media_pid"
media_pid=
python3 - "$artifacts/media-calls.json" <<'PYMEDIA'
import json,sys
calls=json.load(open(sys.argv[1]))
assert ['SetPosition', ['/lumina/track1', 90000000]] in calls,calls
assert [c[0] for c in calls] == ['Play','Pause','Next','SetPosition','Previous','Quit'],calls
PYMEDIA
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
text='\n'.join(p.read_text() for p in Path(sys.argv[1]).parent.glob('*.log') if p.name in ['shell.log','spatial.log','spatial-reload.log','sidebar.log','settings-actions.log','productivity.log','productivity-reload.log','productivity-corrupt.log','media.log'])
errors=[line for line in text.splitlines() if re.search(r'ERROR|ReferenceError|TypeError|is not a type|Cannot assign|Unable to assign|not defined|Binding loop',line)]
if errors: raise SystemExit('\n'.join(errors))
PYLOG
printf 'Shell integration passed: %s\n' "$artifacts"
