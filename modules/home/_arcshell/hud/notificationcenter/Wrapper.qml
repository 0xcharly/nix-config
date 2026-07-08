pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import Quickshell.Hyprland
import QtQuick

Item {
    id: root

    required property ShellScreen screen
    property bool hovered
    readonly property bool shouldBeActive: UiState.isNotificationCenterTargetScreen(root.screen) && Notifications.notClosed.length > 0
    readonly property ThemeConfig.NotificationCenter theme: Config.theme.hud.notificationCenter

    // 0 = collapsed, 1 = open. One master value scales width and height
    // together, so the panel grows out of its top-right corner and a
    // mid-animation reversal retraces the same visual path.
    property real progress: 0

    // Event-driven summon (every screen's instance fires): target the
    // focused monitor; the latch in UiState makes the N calls idempotent.
    function show(): void {
        UiState.setNotificationCenterShown(true, Hyprland.focusedMonitor);
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
        target: Notifications

        function onReceived(): void {
            // Auto-open the tray on arrival unless do-not-disturb; the
            // timer then hides it after `hideDelay` unless hovered.
            if (Notifications.shouldShowPopup())
                root.show();
        }
    }

    Timer {
        id: timer

        interval: root.theme.hideDelay
        onTriggered: {
            // Every instance restarts this timer on the same global event;
            // only the target screen's instance may close, else a never-
            // hovered instance would hide the panel out from under the
            // target screen's cursor.
            if (!root.hovered && UiState.isNotificationCenterTargetScreen(root.screen)) {
                UiState.showNotificationCenter = false;
            }
        }
    }

    // Content revealed from the top-right growth corner.
    Item {
        anchors.fill: parent
        clip: true

        Loader {
            id: content

            anchors.top: parent.top
            anchors.right: parent.right

            // Load as soon as a notification is tracked — before show() flips
            // the state — so the open transition binds an already-settled
            // content.implicitHeight (avoids an implicitHeight binding loop
            // through visible -> active -> load). `root.visible` keeps the
            // content alive through the collapse animation after the last
            // notification is dismissed.
            Component.onCompleted: active = Qt.binding(() => Notifications.notClosed.length > 0 || root.visible)

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
        // Bottom — exposed horizontal edge.
        horizontal: true
        x: (root.width - width) / 2
        y: root.height - root.theme.line.width / 2
    }
    Line {
        // Left — exposed vertical edge.
        horizontal: false
        x: -root.theme.line.width / 2
        y: (root.height - height) / 2
    }
}
