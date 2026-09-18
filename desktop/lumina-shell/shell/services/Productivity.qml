pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

// Lumina persistence for the upstream ii To Do / Pomodoro / stopwatch surfaces.
Singleton {
    id: root
    property bool ready: false
    property string error: ""
    property alias data: data
    property double now: Date.now()
    readonly property var tasks: ready ? data.tasks : []
    readonly property int remainingTasks: tasks.filter(t => !t.done).length
    readonly property int secondsLeft: Math.max(0, Math.ceil((data.deadline > 0 ? data.deadline - now : data.remaining * 1000) / 1000))
    readonly property double stopwatchMs: data.elapsed + (data.started > 0 ? Math.max(0, now - data.started) : 0)
    signal completed(string phase)
    function duration(phase) { return (phase === "focus" ? data.focusMinutes : phase === "break" ? data.breakMinutes : data.longBreakMinutes) * 60; }
    function format(seconds) { const s = Math.max(0, Math.floor(seconds)); return Math.floor(s / 60).toString().padStart(2, "0") + ":" + (s % 60).toString().padStart(2, "0"); }
    function addTask(text) {
        if (!ready || !text.trim()) return false;
        data.tasks = data.tasks.concat([{id: Date.now().toString(36) + Math.random().toString(36).slice(2), text: text.trim().slice(0, 2000), done: false}]);
        return true;
    }
    function toggleTask(id) { if (ready) data.tasks = data.tasks.map(t => t.id === id ? Object.assign({}, t, {done: !t.done}) : t); }
    function restoreTask(task) { if (ready && task && !tasks.some(t => t.id === task.id)) data.tasks = tasks.concat([task]); }
    function deleteTask(id) { if (ready) data.tasks = data.tasks.filter(t => t.id !== id); }
    function updateTime(timestamp) {
        now = timestamp;
        if (!ready || data.deadline <= 0 || now < data.deadline) return;
        const finished = data.phase;
        data.deadline = 0;
        if (finished === "focus") { data.cycles++; data.phase = data.cycles % 4 === 0 ? "long break" : "break"; }
        else data.phase = "focus";
        data.remaining = duration(data.phase);
        // Stop at the boundary; never silently skip focus/break sessions while offline.
        completed(finished);
    }
    function toggleFocus() {
        if (!ready) return;
        const running = data.deadline > 0;
        updateTime(Date.now());
        if (running && data.deadline === 0) return;
        if (running) { data.remaining = secondsLeft; data.deadline = 0; }
        else data.deadline = now + data.remaining * 1000;
    }
    function resetFocus() { if (!ready) return; data.deadline = 0; data.phase = "focus"; data.cycles = 0; data.remaining = duration("focus"); }
    function toggleStopwatch() {
        if (!ready) return;
        now = Date.now();
        if (data.started > 0) { data.elapsed = stopwatchMs; data.started = 0; }
        else data.started = now;
    }
    function lap() { if (ready && data.started > 0) { now = Date.now(); data.laps = data.laps.concat([stopwatchMs]); } }
    function resetStopwatch() { if (ready) { data.started = 0; data.elapsed = 0; data.laps = []; } }
    Timer { interval: 100; running: root.ready; repeat: true; onTriggered: root.updateTime(Date.now()) }
    Timer { id: save; interval: 150; onTriggered: store.writeAdapter() }
    FileView {
        id: store
        path: Config.configDir + "/productivity.json"
        onLoaded: {
            try {
                const saved = JSON.parse(store.text());
                if (saved.tasks !== undefined && (!Array.isArray(saved.tasks) || saved.tasks.some(t => !t || typeof t.id !== "string" || typeof t.text !== "string" || typeof t.done !== "boolean"))) throw new Error("Invalid tasks");
                for (const key of ["focusMinutes", "breakMinutes", "longBreakMinutes"]) if (saved[key] !== undefined && (!Number.isInteger(saved[key]) || saved[key] < 1 || saved[key] > 180)) throw new Error("Invalid duration");
                for (const key of ["deadline", "remaining", "started", "elapsed", "cycles"]) if (saved[key] !== undefined && (typeof saved[key] !== "number" || !Number.isFinite(saved[key]) || saved[key] < 0)) throw new Error("Invalid timer");
                if (saved.laps !== undefined && (!Array.isArray(saved.laps) || saved.laps.some(t => typeof t !== "number" || !Number.isFinite(t) || t < 0))) throw new Error("Invalid laps");
                if (saved.phase !== undefined && !["focus", "break", "long break"].includes(saved.phase)) throw new Error("Invalid phase");
                root.ready = true; root.error = ""; root.updateTime(Date.now());
            } catch (e) { root.ready = false; root.error = "Could not load tasks and timers. Your saved file has been kept."; }
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) root.ready = true;
            else root.error = "Could not load tasks and timers. Your saved file has been kept.";
        }
        onSaved: root.error = ""
        onSaveFailed: error => root.error = "Could not save tasks and timers.";
        onAdapterUpdated: if (root.ready) save.restart()
        JsonAdapter {
            id: data
            property var tasks: []
            property string phase: "focus"
            property int cycles: 0
            property int focusMinutes: 25
            property int breakMinutes: 5
            property int longBreakMinutes: 15
            property double deadline: 0
            property int remaining: 1500
            property double started: 0
            property double elapsed: 0
            property var laps: []
        }
    }
}
