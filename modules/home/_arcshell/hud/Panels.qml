import qs.config
import qs.components.launcher as Launcher
import qs.hud.controlcenter as ControlCenter
import qs.hud.dynamicisland as DynamicIsland
import qs.hud.notificationcenter as NotificationCenter
import Quickshell
import QtQuick

Item {
    id: root

    required property ShellScreen screen
    required property Item bar

    readonly property alias controlCenter: controlCenter
    readonly property alias dynamicIsland: dynamicIsland
    readonly property alias notificationCenter: notificationCenter

    anchors.fill: parent
    anchors.margins: Config.theme.hud.border.width
    anchors.leftMargin: bar.implicitWidth

    ControlCenter.Wrapper {
        id: controlCenter

        screen: root.screen

        anchors.bottom: parent.bottom
        anchors.left: parent.left
    }

    DynamicIsland.Wrapper {
        id: dynamicIsland

        screen: root.screen

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
    }

    NotificationCenter.Wrapper {
        id: notificationCenter

        screen: root.screen

        anchors.top: parent.top
        anchors.right: parent.right
    }

    Launcher.Wrapper {
        id: launcher

        screen: root.screen

        anchors.centerIn: parent
        // Pin the top border at its list-less position while open (list
        // resizes only move the bottom border), but keep the panel centered
        // while opening/closing so the borders part and join symmetrically.
        anchors.verticalCenterOffset: (launcher.height - launcher.restHeight * launcher.heightProgress) / 2
    }
}
