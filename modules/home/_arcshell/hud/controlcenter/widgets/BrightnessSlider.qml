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
        // setBrightness only clamps to [0, 1]; the slider's 5% floor
        // must be enforced here.
        if (event.angleDelta.y > 0) {
            monitor.setBrightness(Math.min(slider.to, monitor.brightness + slider.stepSize));
        } else if (event.angleDelta.y < 0) {
            monitor.setBrightness(Math.max(slider.from, monitor.brightness - slider.stepSize));
        }
    }

    Row {
        id: layout

        spacing: slider.theme.labelSpacing

        ArcSlantedSlider {
            id: slider

            anchors.verticalCenter: parent.verticalCenter

            value: root.brightness
            rawValue: root.brightness
            onMoved: root.monitor?.setBrightness(value)
        }

        ArcSliderLabel {
            anchors.verticalCenter: parent.verticalCenter

            value: slider.value
            icon: IconLibrary.getBrightnessIcon(slider.value)
            held: slider.pressed
            // Requirement: label matches the lit strokes' color.
            color: slider.theme.highlightColor
        }
    }
}
