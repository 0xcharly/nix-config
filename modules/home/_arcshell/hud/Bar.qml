pragma ComponentBehavior: Bound

import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property ShellScreen screen

    readonly property Item topWidgets: topWidgets
    readonly property Item bottomWidgets: bottomWidgets
    readonly property int exclusiveZone: implicitWidth

    anchors.left: parent.left
    anchors.topMargin: Config.tokens.system.measurements.small
    anchors.bottomMargin: Config.tokens.system.measurements.small

    implicitWidth: Config.theme.hud.barWidth

    ColumnLayout {
        id: layout
        anchors.fill: parent

        BarTop {
            id: topWidgets
            screen: root.screen
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            Layout.topMargin: Config.theme.hud.border.width
        }
        BarBottom {
            id: bottomWidgets
            screen: root.screen
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
            Layout.bottomMargin: Config.theme.hud.border.width
        }
    }
}
