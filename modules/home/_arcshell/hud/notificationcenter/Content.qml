pragma ComponentBehavior: Bound

import qs.hud.notificationcenter.widgets
import qs.components
import qs.config
import qs.services
import Quickshell
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    required property ShellScreen screen
    readonly property ThemeConfig.NotificationCenter theme: Config.theme.hud.notificationCenter

    // Rows beyond `maxVisible` collapse into the "x others" line; the
    // service list is newest-first.
    readonly property int overflow: Math.max(0, Notifications.notClosed.length - root.theme.maxVisible)

    implicitWidth: layout.implicitWidth + root.theme.padding.left + root.theme.padding.right - Config.theme.hud.border.width
    implicitHeight: layout.implicitHeight + root.theme.padding.top + root.theme.padding.bottom

    color: Config.theme.hud.border.color

    Behavior on color {
        AnimatedColor {}
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.bottomMargin: root.theme.padding.bottom
        anchors.leftMargin: 0
        anchors.rightMargin: 0
        anchors.topMargin: root.theme.padding.top
        spacing: Config.theme.hud.notificationCenter.spacedBy

        ArcText {
            Layout.fillWidth: true
            Layout.leftMargin: root.theme.padding.left
            Layout.rightMargin: root.theme.padding.right
            elide: Text.ElideRight
            color: Config.tokens.system.colors.on_surface
            style: Config.tokens.system.typography.mediumTitle
            text: qsTr("Notification Center")
        }

        Repeater {
            model: ScriptModel {
                // notClosed is a QQmlListReference (list<> property); ScriptModel
                // wants a QVariantList, so materialize a plain JS array.
                values: Array.from(Notifications.notClosed)
            }

            Notification {}
        }

        ArcText {
            visible: Notifications.notClosed.length === 0
            Layout.fillWidth: true
            Layout.topMargin: Config.tokens.system.measurements.medium
            Layout.bottomMargin: Config.tokens.system.measurements.medium
            horizontalAlignment: Text.AlignHCenter
            color: Config.tokens.system.colors.on_surface_variant
            style: Config.tokens.system.typography.body
            text: qsTr("No notifications.")
        }

        ArcText {
            visible: root.overflow > 0
            Layout.fillWidth: true
            Layout.leftMargin: root.theme.padding.left
            Layout.rightMargin: root.theme.padding.right
            horizontalAlignment: Text.AlignHCenter
            color: Config.tokens.system.colors.on_surface_variant
            style: Config.tokens.system.typography.smallLabel
            text: root.overflow === 1 ? qsTr("1 other") : qsTr("%1 others").arg(root.overflow)
        }
    }
}
