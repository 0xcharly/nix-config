pragma ComponentBehavior: Bound

import qs.components
import qs.services
import Quickshell.Bluetooth
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

RowLayout {
    Layout.fillWidth: true

    QuickToggle {
        enabled: Network.wifiNetwork !== null
        icon: "wifi"
        text: Network.wifiNetwork ?? qsTr("Wi-Fi")

        onLeftClicked: {
            if (!Network.wifiEnabled)
                Network.setWifiEnabled(true);
            UiState.openLauncher("wifi", Hyprland.focusedMonitor);
        }
        onRightClicked: Network.setWifiEnabled(!Network.wifiEnabled)

        Layout.fillWidth: true
        Layout.preferredWidth: 1
    }

    QuickToggle {
        enabled: Bluetooth.defaultAdapter?.enabled === true && Bluetooth.defaultAdapter.devices.values.length > 0
        icon: Bluetooth.defaultAdapter?.enabled === true ? Bluetooth.defaultAdapter.devices.values.filter(device => device.connected).length > 0 ? "bluetooth_connected" : "bluetooth" : "bluetooth_disabled"
        text: Bluetooth.defaultAdapter?.enabled === true && Bluetooth.defaultAdapter.devices.values.filter(device => device.connected).length > 0 ? Bluetooth.defaultAdapter.devices.values.filter(device => device.connected)[0].name : qsTr("Bluetooth")

        onLeftClicked: {
            if (Bluetooth.defaultAdapter && !Bluetooth.defaultAdapter.enabled)
                Bluetooth.defaultAdapter.enabled = true;
            UiState.openLauncher("bluetooth", Hyprland.focusedMonitor);
        }
        onRightClicked: {
            if (Bluetooth.defaultAdapter)
                Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
        }

        Layout.fillWidth: true
        Layout.preferredWidth: 1
    }
}
