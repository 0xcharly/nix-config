import Quickshell
import Quickshell.Wayland

PanelWindow {
    required property string name

    WlrLayershell.namespace: `arc-shell-${name}`
    color: "transparent"
}
