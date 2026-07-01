import qs.config
import qs.services
import Quickshell
import QtQuick

MouseArea {
    id: root

    required property ShellScreen screen
    required property Panels panels
    required property Item bar

    // OSD
    function withinOsdPanelHeight(panel: Item, x: real, y: real): bool {
        const panelY = Config.theme.hud.border.width + panel.y;
        return y >= panelY - Config.theme.hud.osd.shape && y <= panelY + panel.height + Config.theme.hud.osd.shape;
    }

    function inOsdPanel(panel: Item, x: real, y: real): bool {
        return x >= panel.x && withinOsdPanelHeight(panel, x, y);
    }

    function showOsdPanel(panel: Item, x: real, y: real): bool {
      return inOsdPanel(panel, x, y);
    }

    // Control center
    function withinControlCenterPanelWidth(panel: Item, x: real, y: real): bool {
        return x <= panel.x + panel.width + root.bar.width;
    }

    function inControlCenterPanel(panel: Item, x: real, y: real): bool {
        const panelY = Config.theme.hud.border.width + panel.y;
        return y >= panelY /* && y <= panelY + panel.height */ && withinControlCenterPanelWidth(panel, x, y);
    }

    function inBottomLeftHotCorner(panel: Item, x: real, y: real): bool {
      return y >= root.bar.height - root.bar.bottomWidgets.height && x <= root.bar.width
    }

    function showControlCenterPanel(panel: Item, x: real, y: real): bool {
      return inBottomLeftHotCorner(panel, x, y) || inControlCenterPanel(panel, x, y)
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

        UiState.showControlCenter = root.panels.controlCenter.hovered = showControlCenterPanel(panels.controlCenter, x, y);
        UiState.showOsd = root.panels.osd.hovered = showOsdPanel(panels.osd, x, y);
    }
}
