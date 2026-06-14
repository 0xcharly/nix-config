import qs.config
import qs.hud.controlcenter as ControlCenter
import qs.hud.osd as Osd
import QtQuick
import QtQuick.Shapes

Shape {
    id: root

    required property Panels panels
    required property Item bar

    anchors.fill: parent
    anchors.margins: Config.theme.hud.border.width
    anchors.leftMargin: bar.implicitWidth
    preferredRendererType: Shape.CurveRenderer

    ControlCenter.Drawer {
        wrapper: root.panels.controlCenter

        startX: root.width
        startY: root.height
    }

    Osd.Drawer {
        wrapper: root.panels.osd

        startX: root.width
        startY: (root.height - wrapper.height) / 2 - rounding
    }
}
