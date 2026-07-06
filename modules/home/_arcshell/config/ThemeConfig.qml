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
        property FeatureTokens.PowerManagement power: FeatureTokens.PowerManagement {}
        property FeatureTokens.Vpn vpn: FeatureTokens.Vpn {}
        property FeatureTokens.Workspaces workspaces: FeatureTokens.Workspaces {}
    }

    component ControlCenter: JsonObject {
        property int hideDelay: 2000
        property BorderLineValues line: BorderLineValues {}
        property AnimationValues animation: AnimationValues {
            curveIn: Config.tokens.system.animations.curves.emphasizedIn
            curveOut: Config.tokens.system.animations.curves.emphasizedOut
        }
        property ComponentTokens.Slider slider: ComponentTokens.Slider {}
        property PaddingValues padding: PaddingValues {
            bottom: Config.tokens.system.measurements.medium
            left: Config.tokens.system.measurements.large
            right: Config.tokens.system.measurements.large
            top: Config.tokens.system.measurements.large
        }
        property int spacedBy: Config.tokens.system.measurements.medium

        property IdleInhibitor idleInhibitor: IdleInhibitor {}
    }

    component DynamicIsland: JsonObject {
        property int hideDelay: 2000
        property int shape: Config.tokens.system.shapes.cornerMedium
        property PaddingValues padding: PaddingValues {
            bottom: Config.tokens.system.measurements.large
            left: Config.tokens.system.measurements.large
            right: Config.tokens.system.measurements.large
            top: Config.tokens.system.measurements.medium
        }
        property int spacedBy: Config.tokens.system.measurements.medium
    }

    component NotificationCenter: JsonObject {
        property int hideDelay: 2000
        property int maxVisible: 3
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
    }

    component IdleInhibitor: JsonObject {
        property int verticalSpacing: Config.tokens.system.measurements.medium
        property PaddingValues padding: PaddingValues {
            bottom: Config.tokens.system.measurements.medium
            left: Config.tokens.system.measurements.medium
            right: Config.tokens.system.measurements.medium
            top: Config.tokens.system.measurements.medium
        }
        property SurfaceTokens icon: SurfaceTokens {
            colors: SurfaceColorValues {
                surface: Config.tokens.system.colors.surface_accent
                content: Config.tokens.system.colors.on_surface_accent
            }
            padding: PaddingValues {
                bottom: Config.tokens.system.measurements.small
                left: Config.tokens.system.measurements.small
                right: Config.tokens.system.measurements.small
                top: Config.tokens.system.measurements.small
            }
            shape: Config.tokens.system.shapes.cornerFull
            typography: Config.tokens.system.typography.icon
        }
        property SurfaceColorValues iconChecked: SurfaceColorValues {
            surface: Config.tokens.system.colors.surface_done
            content: Config.tokens.system.colors.on_surface_done
        }
        property TypographyValues titleTypography: Config.tokens.system.typography.title
        property TypographyValues bodyTypography: Config.tokens.system.typography.body
        property color bodyContentColor: Config.tokens.system.colors.on_surface_variant
        property SurfaceTokens surface: Config.theme.defaults.cards
        property ComponentTokens.Switch switch_: ComponentTokens.Switch {}
        property SurfaceTokens activeChip: Config.theme.defaults.chips
        property AnimationValues activeChipAnimation: AnimationValues {
            curveIn: Config.tokens.system.animations.curves.expressiveDefaultSpatial
            curveOut: Config.tokens.system.animations.curves.expressiveDefaultSpatial
            duration: Config.tokens.system.animations.durations.expressiveDefaultSpatial
        }
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
