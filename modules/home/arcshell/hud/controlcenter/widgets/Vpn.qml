pragma ComponentBehavior: Bound

import qs.components
import qs.config
import qs.services
import Quickshell.Hyprland
import QtQuick

// VPN row: same status source (services/VpnCheck.qml) and glyphs as
// the old bar icon, restyled as a full-width QuickToggle. The label
// names the selected Tailscale exit node while one is active. Left
// and right click both open the launcher's exit-node selector.
QuickToggle {
    enabled: VpnCheck.status === "mullvad"
    icon: {
        switch (VpnCheck.status) {
        case "mullvad":
            return "vpn_key";
        case "error":
            return "vpn_key_alert";
        default:
            // "exposed" and startup "unknown".
            return "vpn_key_off";
        }
    }
    // Short node name ("jp-tyo-wg-002"): the full FQDN is noise at card
    // width, and the selector spells out the full identity anyway.
    text: ExitNodeSearch.selectedNode ? ExitNodeSearch.selectedNode.hostname.split(".")[0] : qsTr("Exit node")

    onLeftClicked: UiState.openLauncher("exit-node", Hyprland.focusedMonitor)
    onRightClicked: UiState.openLauncher("exit-node", Hyprland.focusedMonitor)

    // The exit-node list otherwise refreshes only when the launcher
    // enters exit-node mode; refresh on panel open so the label is
    // current.
    Connections {
        target: UiState

        function onShowControlCenterChanged() {
            if (UiState.showControlCenter)
                ExitNodeSearch.refresh();
        }
    }
}
