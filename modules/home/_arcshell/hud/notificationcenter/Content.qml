pragma ComponentBehavior: Bound

import qs.hud.notificationcenter.widgets
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property ShellScreen screen
    readonly property ThemeConfig.NotificationCenter theme: Config.theme.hud.notificationCenter

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

        Notification {
          title: "Fake notification title"
          body: "Fake notification body"
        }

        Notification {
          title: "Fake notification title"
          body: "Fake notification body"
        }

        Notification {
          title: "Fake notification title"
          body: "Fake notification body"
        }
    }
}
