pragma Singleton

import qs.components
import qs.services
import Quickshell

Singleton {
    id: root

    property bool showControlCenter: false
    property bool showDynamicIsland: false
    property bool showNotificationCenter: false
    property bool showLauncher: false

    property var screens: new Map()

    function load(screen: ShellScreen, state: var): void {
        screens.set(Hypr.monitorFor(screen), state);
    }

    WaylandShortcut {
        name: "launcherToggle"
        description: "Toggle the launcher"
        onPressed: root.showLauncher = !root.showLauncher
    }
}
