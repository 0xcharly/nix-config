import QtQuick

import Quickshell.Io
import qs.config
import qs.config.tokens.component as ComponentTokens
import qs.config.tokens.feature as FeatureTokens
import qs.config.tokens.types

JsonObject {
    property ComponentDefaults defaults: ComponentDefaults {}
    property Hud hud: Hud {}

    property FeatureTokens.Desktop desktop: FeatureTokens.Desktop {}

    component Hud: JsonObject {
        property BorderValues border: BorderValues {
            color: Config.tokens.system.colors.surface
            shape: Config.tokens.system.shapes.cornerMedium
            width: 0
        }
        property Bar bar: Bar {}
        property ControlCenter controlCenter: ControlCenter {}
        property DynamicIsland dynamicIsland: DynamicIsland {}
        property NotificationCenter notificationCenter: NotificationCenter {}
        property color scrim: Qt.alpha(border.color, 0.2)
        property real opacity: 1
        property int barWidth: 32
    }

    component Bar: JsonObject {
        property int spacedBy: Config.tokens.system.measurements.small

        property FeatureTokens.Clock clock: FeatureTokens.Clock {}
        property FeatureTokens.BarDecorator decorator: FeatureTokens.BarDecorator {}
        property FeatureTokens.PowerManagement power: FeatureTokens.PowerManagement {}
        property FeatureTokens.Workspaces workspaces: FeatureTokens.Workspaces {}
    }

    component ControlCenter: JsonObject {
        // Panel width floor: the remaining widgets (IdleInhibitor,
        // QuickToggles) are fill-width with no intrinsic width, so the
        // panel needs an explicit minimum to not collapse to its padding.
        property int width: 512
        property BorderLineValues line: BorderLineValues {}
        property AnimationValues animation: AnimationValues {
            curveIn: Config.tokens.system.animations.curves.emphasizedIn
            curveOut: Config.tokens.system.animations.curves.emphasizedOut
        }
        property PaddingValues padding: PaddingValues {
            bottom: Config.tokens.system.measurements.medium
            left: Config.tokens.system.measurements.large
            right: Config.tokens.system.measurements.large
            top: Config.tokens.system.measurements.large
        }
        property int spacedBy: Config.tokens.system.measurements.medium

        property ComponentTokens.IdleInhibitor idleInhibitor: ComponentTokens.IdleInhibitor {}
        property PowerProfileSwitch powerProfile: PowerProfileSwitch {}
        property Vpn vpn: Vpn {}
        property ExitNode exitNode: ExitNode {}
    }

    component DynamicIsland: JsonObject {
        property int shape: Config.tokens.system.shapes.cornerMedium
        property PaddingValues padding: PaddingValues {
            bottom: Config.tokens.system.measurements.large
            left: Config.tokens.system.measurements.large
            right: Config.tokens.system.measurements.large
            top: Config.tokens.system.measurements.medium
        }
        property int spacedBy: Config.tokens.system.measurements.medium

        // Device label shown above each slider (sink / monitor name).
        property TypographyValues deviceLabelTypography: Config.tokens.system.typography.smallLabel
        property color deviceLabelColor: Config.tokens.system.colors.on_surface_variant
        property int deviceLabelSpacing: Config.tokens.system.measurements.extraSmall
    }

    component NotificationCenter: JsonObject {
        property int maxVisible: 3
        // Reach of the top-right hot corner along the screen's top edge.
        property int hotCornerSize: 48
        property BorderLineValues line: BorderLineValues {}
        property AnimationValues animation: AnimationValues {
            curveIn: Config.tokens.system.animations.curves.emphasizedIn
            curveOut: Config.tokens.system.animations.curves.emphasizedOut
        }
        property PaddingValues padding: PaddingValues {
            bottom: Config.tokens.system.measurements.large
            left: Config.tokens.system.measurements.large
            right: Config.tokens.system.measurements.large
            top: Config.tokens.system.measurements.medium
        }
        property int spacedBy: Config.tokens.system.measurements.medium

        property Peek peek: Peek {}
    }

    component Peek: JsonObject {
        // Minimum edge of the collapsed count square; width grows for wide counts.
        property int size: 48
        // Milliseconds between pulse starts.
        property int pulseInterval: 10000
        // Grow-and-fade duration of one pulse.
        property AnimationValues pulseAnimation: AnimationValues {
            duration: Config.tokens.system.animations.durations.twoExtraLarge
        }
        property TypographyValues typography: Config.tokens.system.typography.body
        property color countColor: Config.tokens.system.colors.on_surface
        property color pulseColor: Config.tokens.system.colors.surface_accent
        // Horizontal slack around the count once it outgrows `size`.
        property int countPadding: Config.tokens.system.measurements.large
    }

    component PowerProfileSwitch: JsonObject {
        // Config-enabled by default; the widget additionally hides itself at
        // runtime when profile switching is unavailable (hasPerformanceProfile
        // is the only signal that power-profiles-daemon is present).
        property bool enable: true
        property ComponentTokens.SegmentedControl control: ComponentTokens.SegmentedControl {}
    }

    component Vpn: JsonObject {
        // Off by default: the widget's Loader stays inactive so the
        // VpnCheck singleton never starts polling am.i.mullvad.net on
        // hosts without the module.
        property bool enable: false
    }

    component ExitNode: JsonObject {
        // Capability gate, on by default: the home-manager module forces
        // this false when programs.arcshell.tailscale.enable is off (no
        // tailscale binary on the wrapper's PATH).
        property bool enable: true
    }

    component ComponentDefaults: JsonObject {
        property ComponentTokens.QuickToggle quickToggles: ComponentTokens.QuickToggle {}
        property ComponentTokens.Notification notifications: ComponentTokens.Notification {}
        property ComponentTokens.Switch switches: ComponentTokens.Switch {}
        property SurfaceTokens cards: SurfaceTokens {
            colors: SurfaceColorValues {
                content: Config.tokens.system.colors.on_surface
                surface: Config.tokens.system.colors.surface_backdrop
            }
            padding: PaddingValues {
                bottom: Config.tokens.system.measurements.large
                left: Config.tokens.system.measurements.large
                right: Config.tokens.system.measurements.large
                top: Config.tokens.system.measurements.large
            }
            shape: Config.tokens.system.shapes.cornerLarge
            typography: Config.tokens.system.typography.body
        }
        property SurfaceTokens chips: SurfaceTokens {
            colors: SurfaceColorValues {
                content: Config.tokens.system.colors.on_surface_accent
                surface: Config.tokens.system.colors.surface_accent
            }
            padding: PaddingValues {
                bottom: Config.tokens.system.measurements.small
                left: Config.tokens.system.measurements.medium
                right: Config.tokens.system.measurements.medium
                top: Config.tokens.system.measurements.small
            }
            shape: Config.tokens.system.shapes.cornerFull
            typography: Config.tokens.system.typography.smallLabel
        }
    }
}
