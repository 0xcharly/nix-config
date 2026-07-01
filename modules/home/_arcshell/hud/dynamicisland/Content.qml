pragma ComponentBehavior: Bound

import qs.hud.dynamicisland.widgets
import qs.config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    readonly property ThemeConfig.DynamicIsland theme: Config.theme.hud.dynamicisland

    required property real volume
    required property bool muted
    required property real sourceVolume
    required property bool sourceMuted

    implicitWidth: layout.implicitWidth + root.theme.padding.left + root.theme.padding.right - Config.theme.hud.border.width
    implicitHeight: layout.implicitHeight + root.theme.padding.top + root.theme.padding.bottom

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.bottomMargin: root.theme.padding.bottom
        anchors.leftMargin: root.theme.padding.left
        anchors.rightMargin: root.theme.padding.right
        anchors.topMargin: root.theme.padding.top
        spacing: Config.theme.hud.dynamicisland.spacedBy

        VolumeSlider {
          volume: root.volume
          muted: root.muted
          sourceVolume: root.sourceVolume
          sourceMuted: root.sourceMuted
        }
    }
}
