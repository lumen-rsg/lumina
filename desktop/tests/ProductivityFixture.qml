//@ pragma UseQApplication
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
import QtQuick
import Quickshell
import "panels"
import "services"

ShellRoot {
    id: root
    property int step: 0
    property int completions: 0
    property string taskId: ""
    function check(ok, message) { if (!ok) { console.error(message); Qt.exit(1); } }
    function find(item, name) { if (item.objectName === name) return item; for (const child of item.children || []) { const result = find(child, name); if (result) return result; } return null; }
    Connections { target: Productivity; function onCompleted(phase) { root.completions++; } }
    PanelWindow { implicitWidth: 470; implicitHeight: 400; color: "transparent"; ProductivityGroup { id: group; anchors.fill: parent; forceExpanded: true } }
    Timer {
        interval: 250; running: true; repeat: true
        onTriggered: {
            if (Quickshell.env("LUMINA_PRODUCTIVITY_CORRUPT") === "1") {
                if (root.step++ < 2) return;
                root.check(!Productivity.ready && Productivity.error !== "", "Invalid saved state was accepted");
                root.check(!Productivity.addTask("Do not overwrite"), "Invalid state allowed writes");
                console.warn("PRODUCTIVITY_CORRUPT_PASS"); Qt.quit(); return;
            }
            if (!Productivity.ready) { root.check(root.step++ < 20, "Productivity never loaded: " + Productivity.error); return; }
            if (Quickshell.env("LUMINA_PRODUCTIVITY_RELOAD") === "1") {
                root.check(Productivity.tasks.length === 1 && Productivity.tasks[0].done, "Tasks were not restored");
                root.check(Productivity.data.deadline > 0 && Productivity.secondsLeft > 100 && Productivity.secondsLeft <= 123, "Focus deadline did not survive restart");
                root.check(Productivity.data.started > 0 && Productivity.stopwatchMs > 0 && Productivity.data.laps.length === 1, "Stopwatch did not survive restart");
                console.warn("PRODUCTIVITY_RELOAD_PASS"); Qt.quit(); return;
            }
            if (root.step === 0) group.selectTab(1);
            if (root.step === 1) {
                root.check(!Productivity.addTask("   "), "Empty task accepted");
                const input = root.find(group, "taskInput"); root.check(!!input, "Task input missing");
                input.text = "<b>Literal task</b>"; root.find(group, "taskAdd").clicked();
                root.check(Productivity.tasks.length === 1, "Task button failed"); root.taskId = Productivity.tasks[0].id;
                Productivity.toggleTask(root.taskId); root.check(Productivity.tasks[0].done, "Complete task failed");
                const task = Productivity.tasks[0]; Productivity.deleteTask(root.taskId); root.check(Productivity.tasks.length === 0, "Delete failed");
                Productivity.restoreTask(task); Productivity.restoreTask(task); root.check(Productivity.tasks.length === 1 && Productivity.tasks[0].done, "Undo lost state or duplicated task");
                Quickshell.execDetached(["grim", Quickshell.env("LUMINA_QA_ARTIFACTS") + "/tasks.png"]);
            }
            if (root.step === 2) group.selectTab(2);
            if (root.step === 3) { root.find(group, "timerToggle").clicked(); root.check(Productivity.data.deadline > 0, "Start button failed"); Quickshell.execDetached(["grim", Quickshell.env("LUMINA_QA_ARTIFACTS") + "/timer.png"]); }
            if (root.step === 4) {
                Productivity.toggleFocus(); root.check(Productivity.data.deadline === 0, "Pause failed");
                for (let i = 0; i < 7; i++) { Productivity.data.deadline = Date.now() - 1; Productivity.updateTime(Date.now()); }
                root.check(Productivity.data.cycles === 4 && Productivity.data.phase === "long break" && root.completions === 7, "Focus/break progression failed");
                Productivity.updateTime(Date.now() + 999999); root.check(root.completions === 7, "Paused phase repeated notification");
                Productivity.resetFocus(); root.check(Productivity.data.cycles === 0 && Productivity.secondsLeft === 1500, "Reset failed");
                Productivity.toggleStopwatch();
            }
            if (root.step === 5) { Productivity.lap(); Productivity.toggleStopwatch(); root.check(Productivity.stopwatchMs > 0 && Productivity.data.laps.length === 1, "Stopwatch lap/pause failed"); }
            if (root.step === 6) { Productivity.toggleStopwatch(); Productivity.data.remaining = 123; Productivity.toggleFocus(); group.selectTab(0); }
            if (root.step === 9) { console.warn("PRODUCTIVITY_FIXTURE_PASS"); Qt.quit(); }
            root.step++;
        }
    }
}
