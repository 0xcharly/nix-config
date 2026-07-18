import qs.components
import qs.config
import qs.services
import QtQuick

BufferedWheelEventMouseArea {
    id: root

    required property real volume
    required property bool muted

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    function onWheel(event: WheelEvent) {
        if (event.angleDelta.y > 0) {
            Audio.incrementVolume(slider.stepSize);
        } else if (event.angleDelta.y < 0) {
            Audio.decrementVolume(slider.stepSize);
        }
    }

    Column {
        id: layout

        spacing: Config.theme.hud.dynamicIsland.deviceLabelSpacing

        ArcText {
            width: row.implicitWidth
            elide: Text.ElideRight
            style: Config.theme.hud.dynamicIsland.deviceLabelTypography
            color: Config.theme.hud.dynamicIsland.deviceLabelColor
            text: Audio.sink?.description || Audio.sink?.name || qsTr("Unknown Device")
        }

        Row {
            id: row

            spacing: slider.theme.labelSpacing

            ArcMatrixSlider {
                id: slider

                anchors.verticalCenter: parent.verticalCenter

                value: root.volume
                to: Config.services.audio.maxVolume
                onMoved: Audio.setVolume(value)
            }

            ArcSliderLabel {
                anchors.verticalCenter: parent.verticalCenter

                value: slider.value
                icon: IconLibrary.getVolumeIcon(slider.value, root.muted)
                held: slider.pressed
                // Requirement: label matches the lit squares' color.
                color: slider.theme.highlightColor
            }
        }
    }
}
