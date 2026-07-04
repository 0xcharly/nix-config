import qs.config
import qs.hud.dynamicisland as DynamicIsland
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

    DynamicIsland.Drawer {
        wrapper: root.panels.dynamicIsland

        startX: (root.width - wrapper.width) / 2 - rounding
        startY: 0
    }
}
