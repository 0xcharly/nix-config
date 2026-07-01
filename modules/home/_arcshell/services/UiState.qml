pragma Singleton

import qs.services
import Quickshell

Singleton {
    property bool showOsd: false
    property bool showControlCenter: false
    property bool showDynamicIsland: false

    property var screens: new Map()

    function load(screen: ShellScreen, state: var): void {
        screens.set(Hypr.monitorFor(screen), state);
    }
}
