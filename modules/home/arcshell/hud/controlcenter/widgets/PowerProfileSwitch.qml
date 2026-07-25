pragma ComponentBehavior: Bound

import qs.components
import qs.config
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

// Same icons/labels as the launcher command palette
// (services/CommandSearch.qml). Selection state lives in
// power-profiles-daemon: clicking writes PowerProfiles.profile and the
// bound currentIndex follows the daemon's answer, so external changes
// (powerprofilesctl, launcher commands) animate the selector too.
ArcSegmentedControl {
    id: root

    readonly property ThemeConfig.PowerProfileSwitch config: Config.theme.hud.controlCenter.powerProfile

    theme: root.config.control

    // Config-enabled by default, but only shown when profile switching is
    // actually possible (see BarBottom's old gating comment).
    visible: root.config.enable && PowerProfiles.hasPerformanceProfile

    model: [
        {
            icon: "energy_savings_leaf",
            label: qsTr("Power Saver")
        },
        {
            icon: "balance",
            label: qsTr("Balanced")
        },
        {
            icon: "speed",
            label: qsTr("Performance")
        }
    ]

    currentIndex: PowerProfiles.profile === PowerProfile.PowerSaver ? 0 : PowerProfiles.profile === PowerProfile.Performance ? 2 : 1

    onActivated: index => PowerProfiles.profile = index === 0 ? PowerProfile.PowerSaver : index === 2 ? PowerProfile.Performance : PowerProfile.Balanced

    Layout.fillWidth: true
}
