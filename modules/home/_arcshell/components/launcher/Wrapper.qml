pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import qs.config.tokens.component as ComponentTokens
import Quickshell
import QtQuick

Item {
    id: root

    required property ShellScreen screen
    readonly property bool shouldBeActive: UiState.showLauncher

    property ComponentTokens.Launcher theme: Config.tokens.component.launcher

    // 0 = collapsed, 1 = fully open.
    property real progress: 0

    // Natural height of the loaded content; animated by Content itself,
    // so the panel and its border lines track candidate-list resizes.
    readonly property real contentHeight: loader.item?.implicitHeight ?? 0

    // Height of the content without a candidate list, for pinning the
    // panel's top border while the bottom one moves on list resizes.
    readonly property real restHeight: loader.item?.chromeHeight ?? 0

    visible: progress > 0
    implicitWidth: theme.width * progress
    implicitHeight: contentHeight * progress

    states: State {
        name: "visible"
        when: root.shouldBeActive

        PropertyChanges {
            root.progress: 1
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            AnimatedNumber {
                target: root
                property: "progress"
                duration: root.theme.animation.duration
                easing.bezierCurve: root.theme.animation.curveIn
            }
        },
        Transition {
            from: "visible"
            to: ""

            AnimatedNumber {
                target: root
                property: "progress"
                duration: root.theme.animation.duration
                easing.bezierCurve: root.theme.animation.curveOut
            }
        }
    ]

    // Content, revealed from the center as the wrapper grows.
    Item {
        anchors.fill: parent
        clip: true

        Loader {
            id: loader

            anchors.centerIn: parent

            Component.onCompleted: active = Qt.binding(() => root.shouldBeActive || root.visible)

            sourceComponent: Content {
                implicitWidth: root.theme.width
            }
        }
    }

    // Border line that grows lengthwise and fades out at both ends.
    component BorderLine: Rectangle {
        id: line

        required property bool horizontal
        readonly property real length: root.progress * ((horizontal ? root.theme.width : root.contentHeight) + 2 * root.theme.lineOvershoot)
        // Fade fraction of the current length, clamped so both fades never overlap.
        readonly property real fade: Math.min(0.5, root.theme.lineFade / Math.max(length, 1))

        width: horizontal ? length : root.theme.lineWidth
        height: horizontal ? root.theme.lineWidth : length

        gradient: Gradient {
            orientation: line.horizontal ? Gradient.Horizontal : Gradient.Vertical

            GradientStop {
                position: 0
                color: Qt.alpha(root.theme.lineColor, 0)
            }
            GradientStop {
                position: line.fade
                color: root.theme.lineColor
            }
            GradientStop {
                position: 1 - line.fade
                color: root.theme.lineColor
            }
            GradientStop {
                position: 1
                color: Qt.alpha(root.theme.lineColor, 0)
            }
        }
    }

    BorderLine {
        // Top
        horizontal: true
        x: (root.width - width) / 2
        y: -root.theme.lineWidth / 2
    }
    BorderLine {
        // Bottom
        horizontal: true
        x: (root.width - width) / 2
        y: root.height - root.theme.lineWidth / 2
    }
    BorderLine {
        // Left
        horizontal: false
        x: -root.theme.lineWidth / 2
        y: (root.height - height) / 2
    }
    BorderLine {
        // Right
        horizontal: false
        x: root.width - root.theme.lineWidth / 2
        y: (root.height - height) / 2
    }
}
