pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

ArcRectangle {
    id: root

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + root.theme.padding.top + root.theme.padding.bottom

    readonly property ThemeConfig.IdleInhibitor theme: Config.theme.hud.controlCenter.idleInhibitor

    radius: root.theme.surface.shape
    color: root.theme.surface.colors.surface

    RowLayout {
        id: layout

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: root.theme.padding.bottom
        anchors.leftMargin: root.theme.padding.left
        anchors.rightMargin: root.theme.padding.right
        anchors.topMargin: root.theme.padding.top
        spacing: root.theme.verticalSpacing

        // Icon
        ArcRectangle {
            implicitWidth: implicitHeight
            implicitHeight: icon.implicitHeight + root.theme.icon.padding.top + root.theme.padding.bottom

            radius: Config.tokens.system.shapes.cornerFull
            color: IdleInhibitor.enabled ? root.theme.iconChecked.surface : root.theme.icon.colors.surface

            MaterialIcon {
                id: icon

                anchors.centerIn: parent

                text: "coffee"
                style: root.theme.icon.typography
                color: IdleInhibitor.enabled ? root.theme.iconChecked.content : root.theme.icon.colors.content
            }
        }

        // Text status
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            ArcText {
                Layout.fillWidth: true
                text: qsTr("Keep Awake")
                color: root.theme.surface.colors.content
                style: root.theme.titleTypography
                elide: Text.ElideRight
            }

            ArcText {
                Layout.fillWidth: true
                text: IdleInhibitor.enabled ? qsTr("Preventing sleep mode") : qsTr("Normal power management")
                color: root.theme.bodyContentColor
                style: root.theme.bodyTypography
                elide: Text.ElideRight
            }
        }

        ArcSwitch {
            checked: IdleInhibitor.enabled
            onToggled: IdleInhibitor.enabled = checked
        }
    }
}
