pragma ComponentBehavior: Bound

import qs.config
import qs.components
import qs.services
import Quickshell
import Quickshell.Wayland
import QtQuick
import Quickshell.Hyprland

Variants {
    model: Quickshell.screens

    Scope {
        id: screen
        required property ShellScreen modelData

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
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

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
