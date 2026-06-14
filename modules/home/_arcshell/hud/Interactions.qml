import qs.config
import qs.services
import Quickshell
import QtQuick

MouseArea {
    id: root

    required property ShellScreen screen
    required property Panels panels
    required property Item bar

    function withinOsdPanelHeight(panel: Item, x: real, y: real): bool {
        const panelY = Config.theme.hud.border.width + panel.y;
        return y >= panelY - Config.theme.hud.border.shape && y <= panelY + panel.height + Config.theme.hud.border.shape;
    }

    function inOsdPanel(panel: Item, x: real, y: real): bool {
        return x >= panel.x && withinOsdPanelHeight(panel, x, y);
    }

    function withinControlCenterPanelWidth(panel: Item, x: real, y: real): bool {
        return x >= panel.x;
    }

    function inControlCenterPanel(panel: Item, x: real, y: real): bool {
        const panelY = Config.theme.hud.border.width + panel.y;
        return y >= panelY - 1 /* && y <= panelY + panel.height */ && withinControlCenterPanelWidth(panel, x, y);
    }

    anchors.fill: parent
    hoverEnabled: true

    onContainsMouseChanged: {
        if (!containsMouse) {
            UiState.showControlCenter = false;
            root.panels.controlCenter.hovered = false;

            UiState.showOsd = false;
            root.panels.osd.hovered = false;
        }
    }

    onPositionChanged: event => {
        const x = event.x;
        const y = event.y;

        UiState.showControlCenter = root.panels.controlCenter.hovered = inControlCenterPanel(panels.controlCenter, x, y);
        UiState.showOsd = root.panels.osd.hovered = inOsdPanel(panels.osd, x, y);
    }
}
