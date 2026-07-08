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
    readonly property bool shouldBeActive: UiState.isDynamicIslandTargetScreen(root.screen)

    property real volume
    property bool muted

    // Event-driven summon (every screen's instance fires): target the
    // focused monitor; the latch in UiState makes the N calls idempotent.
    function show(): void {
        UiState.setDynamicIslandShown(true, Hyprland.focusedMonitor);
        timer.restart();
    }

    Component.onCompleted: {
        volume = Audio.volume;
        muted = Audio.muted;
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
        target: Audio

        function onMutedChanged(): void {
            root.show();
            root.muted = Audio.muted;
        }

        function onVolumeChanged(): void {
            root.show();
            root.volume = Audio.volume;
        }

        function onSourceMutedChanged(): void {
            root.show();
        }

        function onSourceVolumeChanged(): void {
            root.show();
        }
    }

    Timer {
        id: timer

        interval: Config.theme.hud.dynamicIsland.hideDelay
        onTriggered: {
            // Every instance restarts this timer on the same global event;
            // only the target screen's instance may close, else a never-
            // hovered instance would hide the panel out from under the
            // target screen's cursor.
            if (!root.hovered && UiState.isDynamicIslandTargetScreen(root.screen)) {
                UiState.showDynamicIsland = false;
            }
        }
    }

    Loader {
        id: content

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom

        Component.onCompleted: active = Qt.binding(() => root.shouldBeActive || root.visible)

        sourceComponent: Content {
            volume: root.volume
            muted: root.muted
        }
    }
}
