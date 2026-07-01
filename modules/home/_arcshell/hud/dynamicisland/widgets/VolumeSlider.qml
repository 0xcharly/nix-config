pragma ComponentBehavior: Bound

import qs.components
import qs.config
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property real volume
    required property bool muted
    required property real sourceVolume
    required property bool sourceMuted

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right

        BufferedWheelEventMouseArea {
            implicitHeight: slider.implicitHeight
            Layout.fillWidth: true

            function onWheel(event: WheelEvent) {
                if (event.angleDelta.y > 0) {
                    Audio.incrementVolume();
                } else if (event.angleDelta.y < 0) {
                    Audio.decrementVolume();
                }
            }

            ArcHorizontalSlider {
                id: slider

                anchors.left: parent.left
                anchors.right: parent.right
                implicitHeight: Config.theme.hud.osd.slider.width

                value: root.volume
                labelValue: IconLibrary.getVolumeIcon(value, root.muted)
                to: Config.services.audio.maxVolume
                onMoved: Audio.setVolume(value)
            }
        }
    }
}
