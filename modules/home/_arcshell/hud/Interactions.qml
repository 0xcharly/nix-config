import qs.config
import qs.services
import Quickshell
import QtQuick

MouseArea {
    id: root

    required property ShellScreen screen
    required property Panels panels
    required property Item bar

    // Control center
    function withinControlCenterPanelWidth(panel: Item, x: real, y: real): bool {
        return x <= panel.x + panel.width + root.bar.width;
    }

    function inControlCenterPanel(panel: Item, x: real, y: real): bool {
        const panelY = Config.theme.hud.border.width + panel.y;
        return y >= panelY /* && y <= panelY + panel.height */ && withinControlCenterPanelWidth(panel, x, y);
    }

    function inBottomLeftHotCorner(panel: Item, x: real, y: real): bool {
      return y >= root.bar.height - root.bar.bottomWidgets.height && x <= root.bar.width;
    }

    function showControlCenterPanel(panel: Item, x: real, y: real): bool {
      return inBottomLeftHotCorner(panel, x, y) || inControlCenterPanel(panel, x, y);
    }

    // Dynamic island
    function withinDynamicIslandPanelWidth(panel: Item, x: real, y: real): bool {
      const panelX = root.bar.width + panel.x;
      return x >= panelX - Config.theme.hud.dynamicIsland.shape && x <= panelX + panel.width + Config.theme.hud.dynamicIsland.shape;
    }

    function inDynamicIslandPanel(panel: Item, x: real, y: real): bool {
      return y <= panel.height && withinDynamicIslandPanelWidth(panel, x, y);
    }

    function showDynamicIslandPanel(panel: Item, x: real, y: real): bool {
      return inDynamicIslandPanel(panel, x, y);
    }

    // NotificationCenter
    function withinNotificationCenterPanelWidth(panel: Item, x: real, y: real): bool {
      const panelX = root.bar.width + panel.x;
      return x >= panelX - Config.theme.hud.notificationCenter.line.overshoot && x <= panelX + panel.width + Config.theme.hud.notificationCenter.line.overshoot;
    }

    function inNotificationCenterPanel(panel: Item, x: real, y: real): bool {
      return y <= panel.height && withinNotificationCenterPanelWidth(panel, x, y);
    }

    function showNotificationCenterPanel(panel: Item, x: real, y: real): bool {
      return inNotificationCenterPanel(panel, x, y);
    }

    anchors.fill: parent
    hoverEnabled: true

    onContainsMouseChanged: {
        if (!containsMouse) {
            // Hide only panels this screen owns: another monitor's panel
            // must survive mouse churn on this screen's HUD surfaces.
            if (UiState.isControlCenterTargetScreen(root.screen))
                UiState.showControlCenter = false;
            root.panels.controlCenter.hovered = false;

            if (UiState.isDynamicIslandTargetScreen(root.screen))
                UiState.showDynamicIsland = false;
            root.panels.dynamicIsland.hovered = false;

            if (UiState.isNotificationCenterTargetScreen(root.screen))
                UiState.showNotificationCenter = false;
            root.panels.notificationCenter.hovered = false;
        }
    }

    onPositionChanged: event => {
        const x = event.x;
        const y = event.y;
        const monitor = Hypr.monitorFor(root.screen);

        // A show latches this screen as the panel's target; a hide is only
        // honored from the current target, so mousing over this screen's
        // HUD surfaces cannot dismiss another monitor's panel.
        const controlCenter = root.panels.controlCenter.hovered = showControlCenterPanel(panels.controlCenter, x, y);
        if (controlCenter || UiState.isControlCenterTargetScreen(root.screen))
            UiState.setControlCenterShown(controlCenter, monitor);

        const dynamicIsland = root.panels.dynamicIsland.hovered = showDynamicIslandPanel(panels.dynamicIsland, x, y);
        if (dynamicIsland || UiState.isDynamicIslandTargetScreen(root.screen))
            UiState.setDynamicIslandShown(dynamicIsland, monitor);

        const notificationCenter = root.panels.notificationCenter.hovered = showNotificationCenterPanel(panels.notificationCenter, x, y);
        if (notificationCenter || UiState.isNotificationCenterTargetScreen(root.screen))
            UiState.setNotificationCenterShown(notificationCenter, monitor);
    }
}
