import QtQuick
import Quickshell.Io
import qs.config

JsonObject {
    // Grid: rows × columns squares, one square per percent point.
    // rows * columns must equal 100 for the percent mapping to hold.
    property int rows: 2
    property int columns: 50
    // Square edge length, px.
    property int square: 6
    // Gap between adjacent squares, px.
    property int spacing: 2
    // Slider step as a fraction of the value range (0.02 = 2 percent points).
    property real step: 0.02
    // Corner radius of each square as a fraction of the edge (0.2 = 20%).
    property real squareRoundness: 0.2
    // Gap between the matrix and its companion label, px.
    property int labelSpacing: 16

    property color baseColor: Config.tokens.system.colors.surface_control_slider_matrix_base
    property color highlightColor: Config.tokens.system.colors.surface_control_slider_matrix_highlight
}
