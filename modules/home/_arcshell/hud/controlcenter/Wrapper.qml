pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import QtQuick

Item {
    id: root

    required property ShellScreen screen
    property bool hovered
    readonly property Brightness.Monitor monitor: Brightness.getMonitorForScreen(root.screen)
    readonly property bool shouldBeActive: UiState.showControlCenter
    readonly property ThemeConfig.ControlCenter theme: Config.theme.hud.controlCenter

    // 0 = collapsed, 1 = open. One master value scales width and height
    // together, so the panel grows out of its bottom-left corner and a
    // mid-animation reversal retraces the same visual path.
    property real progress: 0

    function show(): void {
        UiState.showControlCenter = true;
        timer.restart();
    }

    visible: progress > 0
    implicitWidth: content.implicitWidth * progress
    implicitHeight: content.implicitHeight * progress

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

    Connections {
        target: root.monitor

        function onBrightnessChanged(): void {
            root.show();
        }
    }

    Timer {
        id: timer

        interval: root.theme.hideDelay
        onTriggered: {
            if (!root.hovered) {
                UiState.showControlCenter = false;
            }
        }
    }

    // Content revealed from the bottom-left growth corner.
    Item {
        anchors.fill: parent
        clip: true

        Loader {
            id: content

            anchors.left: parent.left
            anchors.bottom: parent.bottom

            Component.onCompleted: active = Qt.binding(() => root.shouldBeActive || root.visible)

            sourceComponent: Content {
                screen: root.screen
                implicitWidth: 512
            }
        }
    }

    component Line: BorderLine {
        thickness: root.theme.line.width
        lineColor: root.theme.line.color
        fadeLength: root.theme.line.fade
        length: root.progress * ((horizontal ? content.implicitWidth : content.implicitHeight) + 2 * root.theme.line.overshoot)
    }

    Line {
        // Top — exposed horizontal edge.
        horizontal: true
        x: (root.width - width) / 2
        y: -root.theme.line.width / 2
    }
    Line {
        // Right — exposed vertical edge.
        horizontal: false
        x: root.width - root.theme.line.width / 2
        y: (root.height - height) / 2
    }
}
