pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Polls the same endpoint as the nixos services-mullvad-exit-node-check
// module: this host egresses via a Mullvad exit node iff
// am.i.mullvad.net reports mullvad_exit_ip == true.
Singleton {
    id: root

    // "unknown" (startup) | "mullvad" | "exposed" | "error"
    property string status: "unknown"

    Timer {
        interval: 2 * 60 * 1000
        repeat: true
        running: true
        triggeredOnStart: true
        // No-op if the previous check is somehow still running
        // (curl's --max-time 30 expires well before the next tick).
        onTriggered: proc.running = true
    }

    Process {
        id: proc

        command: ["curl", "-sS", "--max-time", "30", "https://am.i.mullvad.net/json"]

        stdout: StdioCollector {
            id: stdoutCollector
        }

        onExited: code => { // qmllint disable signal-handler-parameters
            // callLater lets the stdout collector finish first.
            Qt.callLater(() => {
                if (code !== 0) {
                    root.status = "error";
                    return;
                }
                try {
                    root.status = JSON.parse(stdoutCollector.text).mullvad_exit_ip === true ? "mullvad" : "exposed";
                } catch (e) {
                    root.status = "error";
                }
            });
        }
    }
}
