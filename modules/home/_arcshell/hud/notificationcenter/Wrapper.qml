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
    readonly property bool shouldBeActive: UiState.showNotificationCenter && Notifications.notClosed.length > 0

    function show(): void {
        UiState.showNotificationCenter = true;
        timer.restart();
    }

    visible: height > 0
    implicitHeight: 0
    implicitWidth: content.implicitWidth

    states: State {
        name: "visible"
        when: root.shouldBeActive

        PropertyChanges {
            root.implicitHeight: content.implicitHeight
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            AnimatedNumber {
                target: root
                property: "implicitHeight"
                easing.bezierCurve: Config.tokens.system.animations.curves.expressiveDefaultSpatial
            }
        },
        Transition {
            from: "visible"
            to: ""

            AnimatedNumber {
                target: root
                property: "implicitHeight"
                easing.bezierCurve: Config.tokens.system.animations.curves.emphasizedOut
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

        interval: Config.theme.hud.notificationCenter.hideDelay
        onTriggered: {
            if (!root.hovered) {
                UiState.showNotificationCenter = false;
            }
        }
    }

    Loader {
        id: content

        anchors.left: parent.left
        anchors.bottom: parent.bottom

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
