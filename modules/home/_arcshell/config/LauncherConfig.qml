import Quickshell.Io

JsonObject {
    // Prepended to every launched command, e.g. the uwsm `runapp` wrapper.
    // Empty means exec the desktop entry's argv directly.
    property list<string> launchPrefix: []
}
