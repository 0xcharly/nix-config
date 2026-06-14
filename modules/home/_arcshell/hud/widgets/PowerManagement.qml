pragma ComponentBehavior: Bound

import qs.config.tokens.feature as FeatureTokens
import qs.components
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

ArcRectangle {
    id: root

    required property FeatureTokens.PowerManagement theme

    implicitHeight: layout.implicitHeight + root.theme.padding.top + root.theme.padding.bottom
    implicitWidth: layout.implicitWidth + root.theme.padding.left + root.theme.padding.right

    color: root.theme.colors.surface

    ColumnLayout {
        id: layout

        anchors.centerIn: parent

        Layout.alignment: Qt.AlignHCenter
        spacing: root.theme.spacedBy

        Layout.bottomMargin: root.theme.padding.bottom
        Layout.leftMargin: root.theme.padding.left
        Layout.rightMargin: root.theme.padding.right
        Layout.topMargin: root.theme.padding.top

        PowerManagementIcon {
            theme: root.theme.icon
            Layout.alignment: Qt.AlignHCenter
        }

        ArcText {
            id: label
            Layout.alignment: Qt.AlignHCenter

            tabularFigures: true
            color: root.theme.colors.content
            style: root.theme.typography
            text: UPower.displayDevice.percentage === 1.0 ? "∞" : `${Math.floor(UPower.displayDevice.percentage * 100)}%`
        }
    }
}
