pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

Singleton {
    id: root
    property var bindings: []
    property string error: ""
    function refreshBindings() { if (!request.running) request.running = true; }
    function keys(action, argument) {
        const found = bindings.filter(b => b.action === action && (argument === undefined || b.arg === argument));
        return found.length ? found.map(b => b.keys.replace(/\+/g, " + ")).join(" / ") : "Unbound";
    }
    function item(action, label, argument) { return { keys: keys(action, argument), action: label }; }
    readonly property var sections: [
        { title: "Move", color: Appearance.m3colors.m3secondary, items: [
            item("pan_left", "Pan left"), item("pan_right", "Pan right"), item("pan_up", "Pan up"), item("pan_down", "Pan down"),
            {keys: "Alt + drag", action: "Pan freely"}, item("zoom_in", "Zoom in"), item("zoom_out", "Zoom out"),
            item("zoom_reset", "Reset to 100%"), item("reset_view", "Fit all windows"),
            {keys: "3 fingers", action: "Pan the canvas"}, {keys: "4 fingers ↑ / ↓", action: "Open / close overview"}
        ]},
        { title: "Windows", color: Appearance.m3colors.m3primary, items: [
            {keys: "Super + drag", action: "Move / resize at edges"}, item("focus_next", "Focus next window"),
            item("stack_cycle", "Cycle active stack"), item("close_window", "Close focused window"),
            item("toggle_maximize", "Spotlight focused window"), item("fill_viewport", "Fill viewport"),
            item("stack_window", "Stack focused window"), item("unstack_window", "Remove from stack")
        ]},
        { title: "Organize", color: Appearance.m3colors.m3tertiary, items: [
            item("mark_teleport", "Save this area"), item("remove_teleport", "Remove selected point"),
            item("jump_teleport_left", "Teleport left"), item("jump_teleport_right", "Teleport right"),
            item("jump_teleport_up", "Teleport above"), item("jump_teleport_down", "Teleport below"),
            item("jump_teleport_1", "Jump to point 1")
        ]},
        { title: "Desktop", color: Appearance.m3colors.m3secondary, items: bindings.filter(b => b.action === "spawn").map(b => ({
            keys: b.keys.replace(/\+/g, " + "), action: label(b.arg)
        })) }
    ]
    function label(argument) {
        const names = {"launcher toggle": "Find an application", "overview toggle": "Canvas overview", "tiling toggle": "Arrange windows", "settings toggle": "Lumina settings", "notifications toggle": "Control center", "hints toggle": "Controls guide", "session menu": "Session and power", "clock toggle": "Calendar", "assistant toggle": "Assistant"};
        for (const suffix in names) if ((argument || "").endsWith(suffix)) return names[suffix];
        return argument || "Launch application";
    }
    Process {
        id: request
        command: ["chroma-settingsctl", "bindings"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const payload = JSON.parse(text);
                    if (payload.ok) { root.bindings = payload.bindings || []; root.error = ""; }
                    else root.error = payload.error || "Could not read shortcuts";
                } catch (e) { root.error = "Could not read shortcuts"; }
            }
        }
        onExited: code => { if (code !== 0) root.error = "Shortcut service unavailable"; }
    }
}
