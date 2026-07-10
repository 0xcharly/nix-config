pragma Singleton

import qs.services
import Quickshell
import Quickshell.Networking
import QtQuick

Singleton {
    id: root

    // First wifi-capable device; hosts running this shell have at most one.
    readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property var activeNetwork: root.wifiDevice?.networks.values.find(n => n.connected) ?? null
    // Name of the connected wifi network, or null (QuickToggles contract).
    readonly property var wifiNetwork: root.activeNetwork?.name ?? null

    function setWifiEnabled(enabled: bool): void {
        Networking.wifiEnabled = enabled;
    }

    // Active scanning only while the wifi selector is open; Binding's
    // default restoreMode turns it back off when the launcher closes.
    Binding {
        target: root.wifiDevice
        property: "scannerEnabled"
        value: UiState.showLauncher && UiState.launcherMode === "wifi"
        when: root.wifiDevice !== null
    }
}
