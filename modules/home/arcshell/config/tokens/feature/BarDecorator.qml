import QtQuick
import Quickshell.Io
import qs.config

JsonObject {
    // Icon bounding box edge, logical px; overshoot and caps stay inside it.
    property int size: 24
    // Stroke thickness.
    property int thickness: 2
    // Distance each edge extends past its two triangle corners, per end.
    property int overshoot: 5
    // Length of the fade-to-transparent gradient at each edge end.
    property int fade: 6
    property color color: Config.tokens.system.colors.accent_dark
}
