pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import QtQuick.Templates
import qs.config
import qs.config.tokens.component as ComponentTokens

// Horizontal slanted-stroke slider: N chunks leaning "/", lit
// left→right as the value grows, framed by thin top/bottom border
// lines. Chunk 0 is a top-left triangle, the last a bottom-right
// triangle, the rest parallelograms whose top edge is shifted right by
// exactly one stroke width. Chunks flip instantly — no color
// animation — for a crisp, digital feel. The end triangles double as
// range telltales: the first turns lowColor while the source value
// sits below the minimum, the last turns fullColor at the maximum.
Slider {
    id: root

    property ComponentTokens.SlantedSlider theme: Config.tokens.component.slantedSlider

    // Unclamped source value: Slider clamps `value` into [from, to], so
    // sub-minimum external writes (e.g. IPC brightness 3%) are invisible
    // through `value`. Consumers bind the same source as `value` here to
    // unlock the low warning; left unbound it follows `value` and the
    // warning simply never fires.
    property real rawValue: value

    readonly property int strokeW: theme.strokeWidth
    readonly property real stride: theme.strokeWidth + theme.spacing

    // Highlighted chunk count. Integer math on whole percents: value is
    // percent-quantized by Brightness.Monitor.setBrightness, and e.g.
    // 0.15 * 20 floats to 2.999... — floor on the raw product would drop
    // a lit chunk. In-between values (external setters) round DOWN.
    readonly property int lit: Math.floor(Math.round(value * 100) * theme.strokes / (theme.max * 100))

    readonly property bool low: rawValue <= from
    readonly property bool full: lit >= theme.strokes

    from: theme.min
    to: theme.max
    stepSize: theme.step
    orientation: Qt.Horizontal
    snapMode: Slider.SnapAlways

    implicitWidth: (theme.strokes - 1) * stride
    implicitHeight: theme.height + 2 * (theme.borderWidth + theme.borderSpacing)

    // The strip itself shows the value; there is no thumb.
    handle: null

    background: Item {
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            height: root.theme.borderWidth
            color: root.theme.borderColor
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: root.theme.borderWidth
            color: root.theme.borderColor
        }

        Item {
            y: root.theme.borderWidth + root.theme.borderSpacing

            Repeater {
                model: root.theme.strokes

                Shape {
                    id: chunk

                    required property int index

                    x: index === 0 ? 0 : (index - 1) * root.stride + root.theme.spacing
                    y: 0
                    width: 2 * root.strokeW
                    height: root.theme.height
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        strokeColor: "transparent"
                        fillColor: {
                            if (chunk.index === 0 && root.low) {
                                return root.theme.lowColor;
                            }
                            if (chunk.index === root.theme.strokes - 1 && root.full) {
                                return root.theme.fullColor;
                            }
                            return chunk.index < root.lit ? root.theme.highlightColor : root.theme.baseColor;
                        }

                        PathPolyline {
                            path: {
                                const w = root.strokeW;
                                const h = root.theme.height;
                                if (chunk.index === 0) {
                                    // Top-left corner triangle.
                                    return [Qt.point(0, 0), Qt.point(w, 0), Qt.point(0, h), Qt.point(0, 0)];
                                }
                                if (chunk.index === root.theme.strokes - 1) {
                                    // Bottom-right corner triangle.
                                    return [Qt.point(w, 0), Qt.point(w, h), Qt.point(0, h), Qt.point(w, 0)];
                                }
                                // Parallelogram, top edge shifted right by w.
                                return [Qt.point(w, 0), Qt.point(2 * w, 0), Qt.point(w, h), Qt.point(0, h), Qt.point(w, 0)];
                            }
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.NoButton
    }
}
