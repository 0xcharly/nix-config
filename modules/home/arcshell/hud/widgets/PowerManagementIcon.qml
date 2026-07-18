pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.UPower
import qs.components
import qs.config.tokens.feature

MaterialIcon {
    id: root

    property PowerManagementIcon theme

    animate: true
    text: {
        const charging = [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state);
        if (charging) {
          if (UPower.displayDevice.percentage === 1) {
              return "battery_charging_full";
          }
          const level = {
            0: 20,
            1: 20,
            2: 20,
            3: 30,
            4: 30,
            5: 50,
            6: 60,
            7: 60,
            8: 80,
            9: 90,
          };
          return `battery_charging_${level[Math.floor(UPower.displayDevice.percentage * 10)]}`;
        } else {
          if (UPower.displayDevice.percentage === 1) {
              return "battery_full";
          }
          return `battery_${Math.floor(UPower.displayDevice.percentage * 7)}_bar`;
        }
    }
    color: {
        if (!UPower.onBattery && UPower.displayDevice.state === UPowerDeviceState.FullyCharged) {
            root.theme.fullColors.content;
        } else if (!UPower.onBattery) {
            root.theme.colors.content;
        } else if (UPower.displayDevice.percentage > 0.2) {
            root.theme.colors.content;
        } else if (UPower.displayDevice.percentage > 0.1) {
            root.theme.warningColors.content;
        } else {
            root.theme.criticalColors.content;
        }
    }
    fill: 1
}
