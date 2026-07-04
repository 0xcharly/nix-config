pragma ComponentBehavior: Bound

import qs.hud.notificationcenter.widgets
import qs.components
import qs.config
import qs.services
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property ShellScreen screen
    readonly property ThemeConfig.NotificationCenter theme: Config.theme.hud.notificationCenter

    // The `maxVisible` most recent notifications; the service list is
    // newest-first.
    readonly property var visibleNotifications: Notifications.notClosed.slice(0, root.theme.maxVisible)
    readonly property int overflow: Notifications.notClosed.length - visibleNotifications.length

    implicitWidth: layout.implicitWidth + root.theme.padding.left + root.theme.padding.right - Config.theme.hud.border.width
    implicitHeight: layout.implicitHeight + root.theme.padding.top + root.theme.padding.bottom

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.bottomMargin: root.theme.padding.bottom
        anchors.leftMargin: root.theme.padding.left
        anchors.rightMargin: root.theme.padding.right
        anchors.topMargin: root.theme.padding.top
        spacing: Config.theme.hud.notificationCenter.spacedBy

        Repeater {
            model: root.visibleNotifications

            Notification {}
        }

        ArcText {
            visible: root.overflow > 0
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            color: Config.tokens.system.colors.on_surface_variant
            style: Config.tokens.system.typography.smallLabel
            text: root.overflow === 1 ? qsTr("1 other") : qsTr("%1 others").arg(root.overflow)
        }
    }
}
