import QtQuick

// Border line that grows lengthwise and fades to transparent at both ends.
Rectangle {
    id: line

    required property bool horizontal
    // Current full length, including overshoot; the owner animates it.
    required property real length
    required property real thickness
    required property color lineColor
    // Length of the fade-to-transparent gradient at each line end.
    property real fadeLength: 16
    // Fade fraction of the current length, clamped so both fades never overlap.
    readonly property real fade: Math.min(0.5, fadeLength / Math.max(length, 1))

    width: horizontal ? length : thickness
    height: horizontal ? thickness : length

    gradient: Gradient {
        orientation: line.horizontal ? Gradient.Horizontal : Gradient.Vertical

        GradientStop {
            position: 0
            color: Qt.alpha(line.lineColor, 0)
        }
        GradientStop {
            position: line.fade
            color: line.lineColor
        }
        GradientStop {
            position: 1 - line.fade
            color: line.lineColor
        }
        GradientStop {
            position: 1
            color: Qt.alpha(line.lineColor, 0)
        }
    }
}
