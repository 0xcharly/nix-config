import Quickshell.Io

JsonObject {
    // Prepended to every launched command, e.g. the uwsm `runapp` wrapper.
    // Empty means exec the desktop entry's argv directly.
    property list<string> launchPrefix: []

    // Data files for the "." (glyph) search mode; empty disables the mode.
    property string emojiData: ""
    property string unicodeData: ""

    // qalc binary for the "=" (calculator) mode; empty disables the mode.
    property string qalcPath: ""

    // Terminal argv prefix for the "$" (shell command) mode, e.g.
    // ["/path/to/ghostty", "-e"]; the command argv is appended to it.
    // Empty disables the mode.
    property list<string> terminalCommand: []
}
