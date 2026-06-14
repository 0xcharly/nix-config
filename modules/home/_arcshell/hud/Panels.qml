import qs.config
import qs.hud.controlcenter as ControlCenter
import qs.hud.osd as Osd
import Quickshell
import QtQuick

Item {
    id: root

    required property ShellScreen screen
    required property Item bar

    readonly property alias osd: osd
    readonly property alias controlCenter: controlCenter

    anchors.fill: parent
    anchors.margins: Config.theme.hud.border.width
    anchors.leftMargin: bar.implicitWidth

    ControlCenter.Wrapper {
        id: controlCenter

        screen: root.screen

        anchors.bottom: parent.bottom
        anchors.right: parent.right
    }

    Osd.Wrapper {
        id: osd

        clip: false
        screen: root.screen

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
    }
}
