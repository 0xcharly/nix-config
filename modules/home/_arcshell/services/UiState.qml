pragma Singleton

import qs.components
import qs.services
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    property bool showControlCenter: false
    property bool showDynamicIsland: false
    property bool showNotificationCenter: false
    property bool showLauncher: false

    // Monitor the launcher was summoned on. Latched by the toggle shortcut
    // BEFORE showLauncher flips, so per-screen bindings never observe
    // showLauncher == true with a stale target. Typed (not `var`) so QML
    // nulls it if the monitor disconnects while the launcher is open.
    property HyprlandMonitor launcherMonitor: null

    // Whether the launcher should show on `screen`. A null latch (before
    // the first open, or after the latched monitor disconnected) degrades
    // to every screen rather than an invisible-but-open launcher.
    function isLauncherTargetScreen(screen: ShellScreen): bool {
        if (root.launcherMonitor === null)
            return root.showLauncher;
        return root.showLauncher && root.launcherMonitor.name === Hypr.monitorFor(screen)?.name;
    }

    property var screens: new Map()

    function load(screen: ShellScreen, state: var): void {
        screens.set(Hypr.monitorFor(screen), state);
    }

    WaylandShortcut {
        name: "launcherToggle"
        description: "Toggle the launcher"
        onPressed: {
            if (!root.showLauncher)
                root.launcherMonitor = Hyprland.focusedMonitor;
            root.showLauncher = !root.showLauncher;
        }
    }
}
