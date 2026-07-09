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

    // Event-driven summon (every screen's instance fires): target the
    // focused monitor; the latch in UiState makes the N calls idempotent.
    function show(): void {
        UiState.setNotificationCenterShown(true, Hyprland.focusedMonitor);
        timer.restart();
    }

    visible: implicitWidth > 0
    implicitWidth: 0
    implicitHeight: 0

    states: [
        State {
            name: "open"
            when: root.shouldBeActive

            PropertyChanges {
                root.implicitWidth: content.implicitWidth
                root.implicitHeight: content.implicitHeight
                peek.opacity: 0
                content.opacity: 1
            }
        },
        State {
            name: "peek"
            when: Notifications.notClosed.length > 0

            PropertyChanges {
                root.implicitWidth: peek.implicitWidth
                root.implicitHeight: peek.implicitHeight
                peek.opacity: 1
                content.opacity: 0
            }
        }
    ]

    transitions: [
        Transition {
            from: ""
            to: "peek,open"

            AnimatedNumber {
                properties: "implicitWidth,implicitHeight,opacity"
                duration: root.theme.animation.duration
                easing.bezierCurve: root.theme.animation.curveIn
            }
        },
        Transition {
            from: "peek"
            to: "open"

            AnimatedNumber {
                properties: "implicitWidth,implicitHeight,opacity"
                duration: root.theme.animation.duration
                easing.bezierCurve: root.theme.animation.curveIn
            }
        },
        Transition {
            from: "open"
            to: "peek"

            AnimatedNumber {
                properties: "implicitWidth,implicitHeight,opacity"
                duration: root.theme.animation.duration
                easing.bezierCurve: root.theme.animation.curveOut
            }
        },
        Transition {
            to: ""

            AnimatedNumber {
                properties: "implicitWidth,implicitHeight,opacity"
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

            // Notification rows carry MouseAreas and opacity-0 items still
            // hit-test in QML, so hide the content outright while peeked.
            visible: opacity > 0

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

        // Collapsed count badge — the same panel container shrunk. Hovering it
        // re-opens the full center: Interactions' show-zone tracks the wrapper's
        // live width/height, so no interaction code is needed here.
        Rectangle {
            id: peek

            anchors.top: parent.top
            anchors.right: parent.right

            color: Config.theme.hud.border.color
            implicitHeight: root.theme.peek.size
            implicitWidth: Math.max(root.theme.peek.size, countLabel.implicitWidth + 2 * root.theme.peek.countPadding)
            opacity: 0
            visible: opacity > 0

            // Grow-and-fade ping behind the count, repeating every pulseInterval.
            Rectangle {
                id: pulse

                anchors.centerIn: parent
                width: parent.height
                height: parent.height
                radius: height / 2
                color: root.theme.peek.pulseColor
                // Off between pulses; the animation drives both scale and opacity.
                opacity: 0
                scale: 1 / 3

                SequentialAnimation {
                    running: root.state === "peek"
                    loops: Animation.Infinite

                    ParallelAnimation {
                        AnimatedNumber {
                            target: pulse
                            property: "scale"
                            from: 1 / 3
                            to: 1
                            duration: root.theme.peek.pulseAnimation.duration
                            easing.bezierCurve: root.theme.peek.pulseAnimation.curveOut
                        }
                        AnimatedNumber {
                            target: pulse
                            property: "opacity"
                            from: 1
                            to: 0
                            duration: root.theme.peek.pulseAnimation.duration
                            easing.bezierCurve: root.theme.peek.pulseAnimation.curveOut
                        }
                    }
                    PauseAnimation {
                        duration: Math.max(0, root.theme.peek.pulseInterval - root.theme.peek.pulseAnimation.duration)
                    }
                }
            }

            ArcText {
                id: countLabel

                anchors.centerIn: parent
                color: root.theme.peek.countColor
                style: root.theme.peek.typography
                text: Notifications.notClosed.length
            }
        }
    }

    component Line: BorderLine {
        thickness: root.theme.line.width
        lineColor: root.theme.line.color
        fadeLength: root.theme.line.fade
        length: (horizontal ? root.width : root.height) + 2 * root.theme.line.overshoot
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
