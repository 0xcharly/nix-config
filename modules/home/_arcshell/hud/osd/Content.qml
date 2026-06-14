pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Brightness.Monitor monitor

    required property real volume
    required property bool muted
    required property real sourceVolume
    required property bool sourceMuted
    required property real brightness

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors.centerIn: parent
        spacing: Config.theme.hud.osd.spacedBy

        // Speaker volume
        BufferedWheelEventMouseArea {
            implicitWidth: Config.theme.hud.osd.slider.width
            implicitHeight: Config.theme.hud.osd.slider.height
            Layout.topMargin: Config.theme.hud.osd.padding.top
            Layout.leftMargin: Config.theme.hud.osd.padding.left + Config.theme.hud.border.width
            Layout.rightMargin: Config.theme.hud.osd.padding.right

            function onWheel(event: WheelEvent) {
                if (event.angleDelta.y > 0) {
                    Audio.incrementVolume();
                } else if (event.angleDelta.y < 0) {
                    Audio.decrementVolume();
                }
            }

            ArcSlider {
                anchors.fill: parent

                value: root.volume
                labelValue: IconLibrary.getVolumeIcon(value, root.muted)
                to: Config.services.audio.maxVolume
                onMoved: Audio.setVolume(value)
            }
        }

        // Brightness
        BufferedWheelEventMouseArea {
            implicitWidth: Config.theme.hud.osd.slider.width
            implicitHeight: Config.theme.hud.osd.slider.height
            Layout.bottomMargin: Config.theme.hud.osd.padding.bottom
            Layout.leftMargin: Config.theme.hud.osd.padding.left + Config.theme.hud.border.width
            Layout.rightMargin: Config.theme.hud.osd.padding.right

            function onWheel(event: WheelEvent) {
                const monitor = root.monitor;
                if (!monitor) {
                    return;
                }
                if (event.angleDelta.y > 0) {
                    monitor.setBrightness(monitor.brightness + 0.1);
                } else if (event.angleDelta.y < 0) {
                    monitor.setBrightness(monitor.brightness - 0.1);
                }
            }

            ArcSlider {
                anchors.fill: parent

                value: root.brightness
                labelValue: IconLibrary.getBrightnessIcon(value)
                onMoved: root.monitor?.setBrightness(value)
            }
        }
    }
}
