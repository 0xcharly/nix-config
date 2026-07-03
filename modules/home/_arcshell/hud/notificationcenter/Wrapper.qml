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
    readonly property bool shouldBeActive: UiState.showNotificationCenter

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
                easing.bezierCurve: Config.tokens.system.animations.curves.emphasized
            }
        }
    ]

    // Connections {
    //     target: root.notifications
    //
    //     function onNotificationsChanged(): void {
    //         root.show();
    //     }
    // }

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

        Component.onCompleted: active = Qt.binding(() => root.shouldBeActive || root.visible)

        sourceComponent: Content {
            screen: root.screen
            implicitWidth: 512
        }
    }
}
