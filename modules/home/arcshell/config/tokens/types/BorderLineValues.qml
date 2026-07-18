import QtQuick
import Quickshell.Io
import qs.config

JsonObject {
    // Line thickness.
    property int width: 2
    // Distance each border line extends past the panel corner, per line end.
    property int overshoot: 16
    // Length of the fade-to-transparent gradient at each line end.
    property int fade: 12
    property color color: Config.tokens.system.colors.borders_active
}
