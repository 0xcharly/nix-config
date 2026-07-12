pragma Singleton

import qs.services
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import QtQuick

Singleton {
    id: root

    // Media commands target the first actively playing MPRIS player, else
    // the first registered one. `players` re-evaluates on valuesChanged, so
    // availability updates while the palette is open (Content requeries on
    // onPlayersChanged).
    readonly property var players: Mpris.players.values
    readonly property var activePlayer: players.find(p => p.isPlaying) ?? players[0] ?? null

    readonly property int maxResults: 32

    function query(text: string): var {
        const q = text.trim().toLowerCase();
        // Empty query lists every available command (same behavior as the
        // wifi/bluetooth selectors), in curated declaration order.
        return root.commands.filter(c => c.available && (q.length === 0 || c.name.toLowerCase().includes(q))).slice(0, root.maxResults);
    }

    // `toggle` doubles as the launchSelected()/delegate sentinel field:
    // DesktopEntry already has `name`/`icon`/`command`/`execute`, so those
    // cannot discriminate palette rows (see BinSearch for the convention).
    component Command: QtObject {
        required property string name
        // Material Symbols glyph name for the leading icon cell.
        required property string icon
        property bool toggle: false
        property bool checked: false
        property bool available: true
        // Selector-entering commands keep the launcher open.
        property bool keepOpen: false
        property var run
    }

    readonly property list<Command> commands: [
        Command {
            name: qsTr("Clear notifications")
            icon: "clear_all"
            run: () => Notifications.clear()
        },
        Command {
            name: qsTr("Toggle WiFi")
            icon: "wifi"
            toggle: true
            checked: Network.wifiEnabled
            run: () => Network.setWifiEnabled(!Network.wifiEnabled)
        },
        Command {
            name: qsTr("Toggle Bluetooth")
            icon: "bluetooth"
            toggle: true
            checked: Bluetooth.defaultAdapter?.enabled ?? false
            available: Bluetooth.defaultAdapter !== null
            run: () => Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
        },
        Command {
            name: qsTr("Select WiFi network")
            icon: "wifi_find"
            keepOpen: true
            available: Network.wifiDevice !== null
            run: () => {
                // Mirror the controlcenter QuickToggles: entering the
                // selector implies wanting the radio on.
                if (!Network.wifiEnabled)
                    Network.setWifiEnabled(true);
                UiState.launcherMode = "wifi";
            }
        },
        Command {
            name: qsTr("Select Bluetooth device")
            icon: "bluetooth_searching"
            keepOpen: true
            available: Bluetooth.defaultAdapter !== null
            run: () => {
                if (!Bluetooth.defaultAdapter.enabled)
                    Bluetooth.defaultAdapter.enabled = true;
                UiState.launcherMode = "bluetooth";
            }
        },
        Command {
            name: qsTr("Select Exit Node")
            icon: "vpn_lock"
            keepOpen: true
            run: () => UiState.launcherMode = "exit-node"
        },
        Command {
            name: qsTr("Play")
            icon: "play_arrow"
            available: root.activePlayer !== null
            run: () => root.activePlayer?.play()
        },
        Command {
            name: qsTr("Pause")
            icon: "pause"
            available: root.activePlayer !== null
            run: () => root.activePlayer?.pause()
        },
        Command {
            name: qsTr("Stop")
            icon: "stop"
            available: root.activePlayer !== null
            run: () => root.activePlayer?.stop()
        },
        Command {
            name: qsTr("Mute")
            icon: "volume_off"
            toggle: true
            checked: Audio.muted
            run: () => Audio.toggleMute()
        },
        Command {
            name: qsTr("Previous")
            icon: "skip_previous"
            available: root.activePlayer !== null
            run: () => root.activePlayer?.previous()
        },
        Command {
            name: qsTr("Next")
            icon: "skip_next"
            available: root.activePlayer !== null
            run: () => root.activePlayer?.next()
        },
        Command {
            name: qsTr("Brightness Zero")
            icon: "brightness_low"
            run: () => Brightness.getMonitor("active")?.setBrightness(0)
        },
        Command {
            name: qsTr("Brightness Full")
            icon: "brightness_high"
            run: () => Brightness.getMonitor("active")?.setBrightness(1)
        },
        Command {
            name: qsTr("Log out")
            icon: "logout"
            run: () => Quickshell.execDetached(["uwsm", "stop"])
        },
        Command {
            name: qsTr("Suspend")
            icon: "bedtime"
            run: () => Quickshell.execDetached(["systemctl", "suspend"])
        },
        Command {
            name: qsTr("Hibernate")
            icon: "ac_unit"
            run: () => Quickshell.execDetached(["systemctl", "hibernate"])
        },
        Command {
            name: qsTr("Reboot")
            icon: "restart_alt"
            run: () => Quickshell.execDetached(["systemctl", "reboot"])
        },
        Command {
            name: qsTr("Power off")
            icon: "power_settings_new"
            run: () => Quickshell.execDetached(["systemctl", "poweroff"])
        },
        Command {
            name: qsTr("Power Saver")
            icon: "energy_savings_leaf"
            run: () => PowerProfiles.profile = PowerProfile.PowerSaver
        },
        Command {
            name: qsTr("Balanced")
            icon: "balance"
            run: () => PowerProfiles.profile = PowerProfile.Balanced
        },
        Command {
            name: qsTr("Performance")
            icon: "speed"
            available: PowerProfiles.hasPerformanceProfile
            run: () => PowerProfiles.profile = PowerProfile.Performance
        }
    ]
}
