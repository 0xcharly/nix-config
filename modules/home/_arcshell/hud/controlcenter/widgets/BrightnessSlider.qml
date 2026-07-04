pragma ComponentBehavior: Bound

import qs.components
import qs.config
import qs.services
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property ShellScreen screen
    readonly property Brightness.Monitor monitor: Brightness.getMonitorForScreen(root.screen)
    property real brightness: root.monitor?.brightness ?? 0

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

            ArcHorizontalSlider {
                id: slider

                anchors.left: parent.left
                anchors.right: parent.right
                implicitHeight: Config.theme.hud.controlCenter.slider.width

                value: root.brightness
                labelValue: IconLibrary.getBrightnessIcon(value)
                onMoved: root.monitor?.setBrightness(value)
            }
        }
    }
}
