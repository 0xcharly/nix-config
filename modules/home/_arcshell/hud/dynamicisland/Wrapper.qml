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
    readonly property bool shouldBeActive: UiState.showDynamicIsland

    property real volume
    property bool muted
    property real sourceVolume
    property bool sourceMuted

    function show(): void {
        UiState.showDynamicIsland = true;
        timer.restart();
    }

    Component.onCompleted: {
        volume = Audio.volume;
        muted = Audio.muted;
        sourceVolume = Audio.sourceVolume;
        sourceMuted = Audio.sourceMuted;
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
            root.sourceMuted = Audio.sourceMuted;
        }

        function onSourceVolumeChanged(): void {
            root.show();
            root.sourceVolume = Audio.sourceVolume;
        }
    }

    Timer {
        id: timer

        interval: Config.theme.hud.dynamicisland.hideDelay
        onTriggered: {
            if (!root.hovered) {
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
            implicitWidth: 512
            volume: root.volume
            muted: root.muted
            sourceVolume: root.sourceVolume
            sourceMuted: root.sourceMuted
        }
    }
}
