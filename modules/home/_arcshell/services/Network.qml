pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var wifiNetwork: null

    function nmcli(args: list<string>, callback: var): void {
        const proc = nmcliProcess.createObject(root);
        proc.cmdArgs = ["-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device", "status"];
        proc.callback = callback

        Qt.callLater(() => {
            proc.exec(["nmcli", ...proc.cmdArgs]);
        });
    }

    function getWifiStatus(): void {
      nmcli([/* TODO */], result => {
          if (result.success) {
              const lines = result.output.trim().split("\n");
              for (const line of lines) {
                const parts = line.split(":", /* limit= */ 4);
                if (parts.length === 4 && parts[1] === "wifi" && parts[2] === "connected") {
                  wifiNetwork = parts[3];
                  return;
                }
              }
          } else {
              wifiNetwork = null
          }
      });
    }

    Component.onCompleted: {
      getWifiStatus();
    }

    Component {
        id: nmcliProcess

        NmcliProcess {}
    }

    component NmcliProcess: Process {
        id: proc

        property var callback: null
        property list<string> cmdArgs: []
        property bool callbackCalled: false
        property int exitCode: 0

        signal processFinished

        environment: ({
                LANG: "C.UTF-8",
                LC_ALL: "C.UTF-8"
            })

        stdout: StdioCollector {
            id: stdoutCollector
        }

        stderr: StdioCollector {
            id: stderrCollector

            onStreamFinished: {
                const error = text.trim();
                if (error && error.length > 0) {
                    const output = (stdoutCollector && stdoutCollector.text) ? stdoutCollector.text : "";
                    // root.handlePasswordRequired(proc, error, output, -1);
                }
            }
        }

        onExited: code => { // qmllint disable signal-handler-parameters
            exitCode = code;

            Qt.callLater(() => {
                if (callbackCalled) {
                    processFinished();
                    return;
                }

                if (proc.callback) {
                    const output = (stdoutCollector && stdoutCollector.text) ? stdoutCollector.text : "";
                    const error = (stderrCollector && stderrCollector.text) ? stderrCollector.text : "";
                    const success = code === 0;
                    // const cmdIsConnection = isConnectionCommand(proc.cmdArgs);

                    // if (root.handlePasswordRequired(proc, error, output, exitCode)) {
                    //     processFinished();
                    //     return;
                    // }

                    // const needsPassword = cmdIsConnection && root.detectPasswordRequired(error);

                    // if (!success && cmdIsConnection && root.pendingConnection) {
                    //     const failedSsid = root.pendingConnection.ssid;
                    //     root.connectionFailed(failedSsid);
                    // }

                    callbackCalled = true;
                    callback({
                        success: success,
                        output: output,
                        error: error,
                        exitCode: code,
                        // needsPassword: needsPassword || false
                    });
                    processFinished();
                } else {
                    processFinished();
                }
            });
        }
    }
}
