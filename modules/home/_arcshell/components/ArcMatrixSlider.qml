pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates
import qs.config
import qs.config.tokens.component as ComponentTokens

// Horizontal matrix slider: rows × columns squares, one per percent
// point, lit column by column (left→right, bottom→top within a column)
// as the value grows. Squares flip instantly — no color animation —
// for a crisp, digital feel.
Slider {
    id: root

    property ComponentTokens.MatrixSlider theme: Config.tokens.component.matrixSlider

    readonly property int cells: theme.rows * theme.columns
    // Lit square count; `position` tracks the drag live (`live` default).
    readonly property int lit: Math.round(position * cells)
    readonly property real stride: theme.square + theme.spacing

    orientation: Qt.Horizontal
    // Token-driven step (fraction of the range), quantized while dragging.
    stepSize: (to - from) * theme.step
    snapMode: Slider.SnapAlways

    implicitWidth: theme.columns * stride - theme.spacing
    implicitHeight: theme.rows * stride - theme.spacing

    // The matrix itself shows the value; there is no thumb.
    handle: null

    background: Item {
        Repeater {
            model: root.cells

            Rectangle {
                required property int index
                // Column-major: index 0..rows-1 = first column bottom→top.
                readonly property int col: Math.floor(index / root.theme.rows)
                readonly property int row: index % root.theme.rows

                x: col * root.stride
                y: (root.theme.rows - 1 - row) * root.stride
                width: root.theme.square
                height: root.theme.square
                radius: root.theme.square * root.theme.squareRoundness
                color: index === root.lit - 1 ? root.theme.currentColor : index < root.lit ? root.theme.highlightColor : root.theme.baseColor
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
