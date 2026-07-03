import qs.config
import qs.components.launcher as Launcher
import qs.hud.controlcenter as ControlCenter
import qs.hud.dynamicisland as DynamicIsland
import qs.hud.notificationcenter as NotificationCenter
import qs.hud.osd as Osd
import Quickshell
import QtQuick

Item {
    id: root

    required property ShellScreen screen
    required property Item bar

    readonly property alias controlCenter: controlCenter
    readonly property alias dynamicIsland: dynamicIsland
    readonly property alias osd: osd
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

    Osd.Wrapper {
        id: osd

        screen: root.screen

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
    }

    Launcher.Wrapper {
        id: launcher

        screen: root.screen

        anchors.centerIn: parent
        // Keep the top border where the list-less panel would have it, so
        // candidate-list resizes only move the bottom border.
        anchors.verticalCenterOffset: (launcher.height - launcher.restHeight) / 2
    }
}
