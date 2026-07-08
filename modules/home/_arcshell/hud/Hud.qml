pragma ComponentBehavior: Bound

import qs.config
import qs.components
import qs.services
import Quickshell
import Quickshell.Wayland
import QtQuick
import Quickshell.Hyprland

Scope {
    // One grab whitelisting every screen's HUD window: Hyprland holds a
    // single seat grab, so per-screen grabs driven by the same global
    // showLauncher would replace — and thereby dismiss — each other.
    HyprlandFocusGrab {
        active: UiState.showLauncher
        windows: huds.instances.map(scope => scope.hudWindow)
        // Compositor-side dismissal only (e.g. click outside the HUD).
        // Not emitted on programmatic `active = false`, so Escape/Enter
        // closes never re-enter here. On grab end Hyprland restores
        // keyboard focus to the previous toplevel.
        onCleared: UiState.showLauncher = false
    }

    Variants {
        id: huds

        model: Quickshell.screens

        Scope {
            id: screen

            required property ShellScreen modelData
            readonly property ArcWindow hudWindow: win

            property HyprlandWorkspace workspace: Hypr.monitorFor(modelData).activeWorkspace

            HudExclusiveZones {
                screen: screen.modelData
                bar: bar
            }

            ArcWindow {
                id: win

                name: "hud"
                screen: screen.modelData
                WlrLayershell.exclusionMode: ExclusionMode.Ignore
                // OnDemand, never Exclusive: an exclusive layer registers in
                // Hyprland's m_exclusiveLSes, which makes its focus-restore
                // path bail when the launcher closes (keys eaten until the
                // user clicks). Focus acquisition is done by the grab above.
                // Only the summon screen's window requests focus: Content is
                // loaded only there, so keystrokes must not land elsewhere.
                WlrLayershell.keyboardFocus: UiState.isLauncherTargetScreen(screen.modelData) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

                mask: Region {
                    x: bar.implicitWidth
                    y: Config.theme.hud.border.width + 1
                    width: win.width - bar.implicitWidth - Config.theme.hud.border.width - 1
                    height: win.height - Config.theme.hud.border.width * 2 - 2
                    intersection: Intersection.Xor

                    regions: regions.instances
                }

                anchors.top: true
                anchors.bottom: true
                anchors.left: true
                anchors.right: true

                Variants {
                    id: regions

                    model: panels.children

                    Region {
                        required property Item modelData

                        x: modelData.x + bar.implicitWidth
                        y: modelData.y + Config.theme.hud.border.width
                        width: modelData.width
                        height: modelData.height
                        intersection: Intersection.Subtract
                    }
                }

                Item {
                    anchors.fill: parent
                    opacity: Config.theme.hud.opacity

                    Drawers {
                        bar: bar
                        panels: panels
                    }

                    HudBorder {
                        bar: bar
                    }
                }

                Interactions {
                    screen: screen.modelData
                    panels: panels
                    bar: bar

                    Panels {
                        id: panels

                        screen: screen.modelData
                        bar: bar
                    }

                    Bar {
                        id: bar
                        screen: screen.modelData

                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                    }
                }
            }
        }
    }
}
