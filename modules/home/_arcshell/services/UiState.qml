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

    // Monitor each panel was summoned on. Latched by the set*Shown helpers
    // BEFORE the show flag flips, so per-screen bindings never observe a
    // shown panel with a stale target. Typed (not `var`) so QML nulls them
    // if the monitor disconnects while the panel is open.
    property HyprlandMonitor controlCenterMonitor: null
    property HyprlandMonitor dynamicIslandMonitor: null
    property HyprlandMonitor notificationCenterMonitor: null
    property HyprlandMonitor launcherMonitor: null

    // Whether a panel latched to `monitor` with visibility `shown` should
    // show on `screen`. A null latch (before the first open, or after the
    // latched monitor disconnected) degrades to every screen rather than
    // an invisible-but-open panel.
    function isTargetScreen(shown: bool, monitor: HyprlandMonitor, screen: ShellScreen): bool {
        if (monitor === null)
            return shown;
        return shown && monitor.name === Hypr.monitorFor(screen)?.name;
    }

    function isControlCenterTargetScreen(screen: ShellScreen): bool {
        return isTargetScreen(root.showControlCenter, root.controlCenterMonitor, screen);
    }

    function isDynamicIslandTargetScreen(screen: ShellScreen): bool {
        return isTargetScreen(root.showDynamicIsland, root.dynamicIslandMonitor, screen);
    }

    function isNotificationCenterTargetScreen(screen: ShellScreen): bool {
        return isTargetScreen(root.showNotificationCenter, root.notificationCenterMonitor, screen);
    }

    function isLauncherTargetScreen(screen: ShellScreen): bool {
        return isTargetScreen(root.showLauncher, root.launcherMonitor, screen);
    }

    // Show/hide a panel, latching `monitor` on the hidden -> shown
    // transition only: a re-show while open keeps the original target so
    // the panel never hops screens (and unloads its content) mid-
    // interaction. Pure hide sites may keep assigning the flag directly.
    function setControlCenterShown(shown: bool, monitor: HyprlandMonitor): void {
        if (shown && !root.showControlCenter)
            root.controlCenterMonitor = monitor;
        root.showControlCenter = shown;
    }

    function setDynamicIslandShown(shown: bool, monitor: HyprlandMonitor): void {
        if (shown && !root.showDynamicIsland)
            root.dynamicIslandMonitor = monitor;
        root.showDynamicIsland = shown;
    }

    function setNotificationCenterShown(shown: bool, monitor: HyprlandMonitor): void {
        if (shown && !root.showNotificationCenter)
            root.notificationCenterMonitor = monitor;
        root.showNotificationCenter = shown;
    }

    function setLauncherShown(shown: bool, monitor: HyprlandMonitor): void {
        if (shown && !root.showLauncher)
            root.launcherMonitor = monitor;
        root.showLauncher = shown;
    }

    property var screens: new Map()

    function load(screen: ShellScreen, state: var): void {
        screens.set(Hypr.monitorFor(screen), state);
    }

    WaylandShortcut {
        name: "launcherToggle"
        description: "Toggle the launcher"
        onPressed: root.setLauncherShown(!root.showLauncher, Hyprland.focusedMonitor)
    }
}
