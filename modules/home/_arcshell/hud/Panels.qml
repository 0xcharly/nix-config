import qs.config
import qs.hud.controlcenter as ControlCenter
import qs.hud.dynamicisland as DynamicIsland
import qs.hud.osd as Osd
import Quickshell
import QtQuick

Item {
    id: root

    required property ShellScreen screen
    required property Item bar

    readonly property alias osd: osd
    readonly property alias controlCenter: controlCenter
    readonly property alias dynamicisland: dynamicisland

    anchors.fill: parent
    anchors.margins: Config.theme.hud.border.width
    anchors.leftMargin: bar.implicitWidth

    ControlCenter.Wrapper {
        id: controlCenter

        screen: root.screen

        anchors.bottom: parent.bottom
        anchors.left: parent.left
    }

    Osd.Wrapper {
        id: osd

        screen: root.screen

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
    }

    DynamicIsland.Wrapper {
        id: dynamicisland

        screen: root.screen

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
    }
}
