pragma ComponentBehavior: Bound

import qs.hud.controlcenter.widgets
import qs.components
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    required property ShellScreen screen
    readonly property ThemeConfig.ControlCenter theme: Config.theme.hud.controlCenter

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
        anchors.leftMargin: root.theme.padding.left
        anchors.rightMargin: root.theme.padding.right
        anchors.topMargin: root.theme.padding.top
        spacing: Config.theme.hud.controlCenter.spacedBy

        BrightnessSlider {
            screen: root.screen
        }
        IdleInhibitor {}
        QuickToggles {}
    }
}
