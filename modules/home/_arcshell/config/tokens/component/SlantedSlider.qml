import QtQuick
import Quickshell.Io
import qs.config

JsonObject {
    // Visible chunk count. Chunk 0 is a top-left triangle, the last a
    // bottom-right triangle, the rest parallelograms leaning "/".
    property int strokes: 20
    // Horizontal width of each stroke, px (measured along either
    // horizontal edge). The slant offset is NOT a separate knob: the
    // top edge is always shifted right by exactly `strokeWidth`, which
    // is what makes the end chunks exact corner triangles.
    property int strokeWidth: 16
    // Horizontal gap between adjacent strokes, px.
    property int spacing: 8
    // Strip height, px. Equal to strokeWidth so the stroke edges sit
    // at exactly 45 degrees.
    property int height: 16
    // Top/bottom border lines framing the strip.
    property int borderWidth: 2
    // Gap between each border line and the strip, px.
    property int borderSpacing: 6
    // Value range and step, in brightness fraction (0.05 = 5%).
    property real min: 0.05
    property real max: 1.0
    property real step: 0.05
    // Gap between the strip and its companion label, px.
    property int labelSpacing: 16

    property color baseColor: Config.tokens.system.colors.surface_control_slider_slanted_base
    property color highlightColor: Config.tokens.system.colors.surface_control_slider_slanted_highlight
    property color borderColor: Config.tokens.system.colors.on_surface
    // First triangle while the source value sits below `min`.
    property color lowColor: Config.tokens.system.colors.on_surface_danger
    // Last triangle at `max`.
    property color fullColor: Config.tokens.system.colors.on_surface_success
}
