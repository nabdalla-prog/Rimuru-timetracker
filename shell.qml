//@ pragma AppId rimuru.timetracker
import QtQuick
import Quickshell
import Quickshell.Io
import "qml"

// Time Tracker: a standalone app window. Closing the window hides it; the
// app keeps running so reminders and goal notifications still arrive.
// `omarchy-timetracker` (bin/) shows it again, or starts it.
ShellRoot {
    id: shell

    Store {
        id: store
    }

    property bool shown: Quickshell.env("TIMETRACKER_HIDDEN") !== "1"

    FloatingWindow {
        id: win
        visible: shell.shown
        title: "Time Tracker"
        implicitWidth: 420
        implicitHeight: 760
        minimumSize: Qt.size(360, 560)
        color: "#000000"
        onClosed: shell.shown = false

        Main {
            id: main
            anchors.fill: parent
            store: store
            Component.onCompleted: forceActiveFocus()
        }
    }

    // Qt crashes if the app exits while an item still has keyboard focus
    // (QInputMethod::commit during teardown), so drop focus and hide the
    // window first, then exit a moment later.
    function quit() {
        store.save();
        main.focus = false;
        shell.shown = false;
        quitTimer.start();
    }
    Timer {
        id: quitTimer
        interval: 300
        onTriggered: Qt.quit()
    }

    // `quickshell ipc -p <dir> call timetracker <fn>`; bin/omarchy-timetracker wraps it.
    IpcHandler {
        target: "timetracker"
        function open(): void {
            shell.shown = true;
        }
        function hide(): void {
            shell.shown = false;
        }
        function toggleWindow(): void {
            shell.shown = !shell.shown;
        }
        // Start or stop an activity by name, e.g. `toggle Reading`.
        function toggle(name: string): string {
            var a = store.findActivity(name);
            if (!a)
                return "No activity called " + name;
            store.toggle(a.id);
            return store.status();
        }
        function stop(): string {
            store.stopAll();
            return "Stopped";
        }
        function status(): string {
            return store.status();
        }
        // Switch to a tab: 0 Tracking, 1 Events, 2 Timeline, 3 Goals, 4 Settings.
        function tab(index: int): void {
            main.tab = Math.max(0, Math.min(4, index));
            shell.shown = true;
        }
        // Open a sheet: activity, event, goal, visible, about ("" closes).
        function sheet(name: string): void {
            shell.shown = true;
            if (name === "")
                main.closeSheets();
            else
                main.openSheet(name);
        }
        function exportCsv(): void {
            store.exportCsv();
        }
        function quit(): void {
            shell.quit();
        }
    }
}
