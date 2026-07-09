import qs.components
import qs.config
import qs.services
import Quickshell
import QtQuick

BufferedWheelEventMouseArea {
    id: root

    required property ShellScreen screen
    readonly property Brightness.Monitor monitor: Brightness.getMonitorForScreen(root.screen)
    property real brightness: root.monitor?.brightness ?? 0

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    function onWheel(event: WheelEvent) {
        const monitor = root.monitor;
        if (!monitor) {
            return;
        }
        // Coarse step; setBrightness clamps to [0, 1].
        if (event.angleDelta.y > 0) {
            monitor.setBrightness(monitor.brightness + Config.services.brightness.step);
        } else if (event.angleDelta.y < 0) {
            monitor.setBrightness(monitor.brightness - Config.services.brightness.step);
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
            text: root.screen.model || root.screen.name
        }

        Row {
            id: row

            spacing: slider.theme.labelSpacing

            ArcMatrixSlider {
                id: slider

                anchors.verticalCenter: parent.verticalCenter

                value: root.brightness
                onMoved: root.monitor?.setBrightness(value)
            }

            ArcSliderLabel {
                anchors.verticalCenter: parent.verticalCenter

                value: slider.value
                icon: IconLibrary.getBrightnessIcon(slider.value)
                held: slider.pressed
                // Requirement: label matches the lit squares' color.
                color: slider.theme.highlightColor
            }
        }
    }
}
