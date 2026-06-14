pragma ComponentBehavior: Bound

import qs.config
import qs.hud.widgets
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: layout

    required property ShellScreen screen

    spacing: Config.theme.hud.bar.spacedBy

    Workspaces {
        id: workspaces
        theme: Config.theme.hud.bar.workspaces
        screen: layout.screen
    }
}
