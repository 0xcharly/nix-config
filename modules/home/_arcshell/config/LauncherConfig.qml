import Quickshell.Io

JsonObject {
    // Prepended to every launched command, e.g. the uwsm `runapp` wrapper.
    // Empty means exec the desktop entry's argv directly.
    property list<string> launchPrefix: []

    // Data files for the "." (glyph) search mode; empty disables the mode.
    property string emojiData: ""
    property string unicodeData: ""
}
