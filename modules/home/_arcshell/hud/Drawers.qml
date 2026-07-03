import qs.config
import qs.hud.controlcenter as ControlCenter
import qs.hud.dynamicisland as DynamicIsland
import qs.hud.notificationcenter as NotificationCenter
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

        startX: 0
        startY: root.height
    }

    DynamicIsland.Drawer {
        wrapper: root.panels.dynamicIsland

        startX: (root.width - wrapper.width) / 2 - rounding
        startY: 0
    }

    NotificationCenter.Drawer {
        wrapper: root.panels.notificationCenter

        startX: root.width - wrapper.width - rounding
        startY: 0
    }

    Osd.Drawer {
        wrapper: root.panels.osd

        startX: root.width
        startY: (root.height - wrapper.height) / 2 - rounding
    }
}
