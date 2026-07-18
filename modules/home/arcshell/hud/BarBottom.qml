pragma ComponentBehavior: Bound

import qs.config
import qs.hud.widgets
import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower

ColumnLayout {
    id: layout

    required property ShellScreen screen

    spacing: Config.theme.hud.bar.spacedBy

    Loader {
        asynchronous: true
        // active (not just visible): an inactive Loader never
        // instantiates the widget, so the VpnCheck singleton never
        // starts polling while the module is disabled.
        active: Config.theme.hud.bar.vpn.enable
        visible: Config.theme.hud.bar.vpn.enable

        Layout.alignment: Qt.AlignHCenter

        sourceComponent: Vpn {
            theme: Config.theme.hud.bar.vpn
        }
    }

    Loader {
        asynchronous: true
        // Config-enabled by default, but only shown when profile switching
        // is actually possible: hasPerformanceProfile is 0.3.0's only
        // signal that power-profiles-daemon is present.
        visible: Config.theme.hud.bar.powerProfile.enable && PowerProfiles.hasPerformanceProfile

        Layout.alignment: Qt.AlignHCenter

        sourceComponent: PowerProfileIcon {
            theme: Config.theme.hud.bar.powerProfile
        }
    }

    Loader {
        asynchronous: true
        visible: Config.theme.hud.bar.power.enable

        Layout.alignment: Qt.AlignHCenter

        sourceComponent: PowerManagement {
            theme: Config.theme.hud.bar.power
        }
    }

    Clock {
        theme: Config.theme.hud.bar.clock
        Layout.alignment: Qt.AlignHCenter
    }
}
