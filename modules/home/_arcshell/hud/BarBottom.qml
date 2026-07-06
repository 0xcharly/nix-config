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
