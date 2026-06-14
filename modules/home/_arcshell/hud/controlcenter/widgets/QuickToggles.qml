pragma ComponentBehavior: Bound

import qs.components
import qs.services
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

RowLayout {
    Layout.fillWidth: true

    QuickToggle {
        enabled: Network.wifiNetwork !== null
        icon: "wifi"
        text: Network.wifiNetwork ?? qsTr("Wi-Fi")

        Layout.fillWidth: true
        Layout.preferredWidth: 1
    }

    QuickToggle {
        enabled: Bluetooth.defaultAdapter?.enabled === true && Bluetooth.defaultAdapter.devices.values.length > 0
        icon: Bluetooth.defaultAdapter?.enabled === true ? Bluetooth.defaultAdapter.devices.values.filter(device => device.connected).length > 0 ? "bluetooth_connected" : "bluetooth" : "bluetooth_disabled"
        text: Bluetooth.defaultAdapter?.enabled === true && Bluetooth.defaultAdapter.devices.values.filter(device => device.connected).length > 0 ? Bluetooth.defaultAdapter.devices.values.filter(device => device.connected)[0].name : qsTr("Bluetooth")

        Layout.fillWidth: true
        Layout.preferredWidth: 1
    }
}
