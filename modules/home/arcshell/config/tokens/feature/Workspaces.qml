import QtQuick
import Quickshell.Io
import qs.config
import qs.config.tokens.types

JsonObject {
    property int spacedBy: Config.tokens.system.measurements.extraSmall
    property PaddingValues padding: PaddingValues {
        bottom: Config.tokens.system.measurements.none
        left: Config.tokens.system.measurements.none
        right: Config.tokens.system.measurements.none
        top: Config.tokens.system.measurements.none
    }

    // Slide animation of the shared background indicator behind the active
    // workspace. Defaults: standard curve, medium duration.
    property AnimationValues animation: AnimationValues {}

    property Workspace inactive: Workspace {
        colors: SurfaceColorValues {
            surface: Config.tokens.system.colors.transparent
            content: Config.tokens.system.colors.on_surface_dim
        }
    }

    property Workspace active: Workspace {
        colors: SurfaceColorValues {
            surface: Config.tokens.system.colors.surface_accent
            content: Config.tokens.system.colors.on_surface_accent
        }
    }

    property Workspace hovered: Workspace {
        colors: SurfaceColorValues {
            surface: Config.tokens.system.colors.surface_done
            content: Config.tokens.system.colors.on_surface_done
        }
    }

    property Workspace needsAttention: Workspace {
        colors: SurfaceColorValues {
            surface: Config.tokens.system.colors.surface_danger
            content: Config.tokens.system.colors.on_surface_danger
        }
    }

    property Workspace addButton: Workspace {
        colors: SurfaceColorValues {
            surface: Config.tokens.system.colors.surface_elevated
            content: Config.tokens.system.colors.on_surface
        }
        // Icon family at the workspace-label metrics so the glyph button
        // matches the numeral chips' size.
        typography: TypographyValues {
            family: Config.tokens.system.typography.icon.family
            fontSize: Config.tokens.system.typography.body.fontSize
            lineHeight: Config.tokens.system.typography.body.lineHeight
            weight: Config.tokens.system.typography.body.weight
        }
    }

    // Hover state of the add button: same metrics, brighter surface.
    property Workspace addButtonHovered: Workspace {
        colors: SurfaceColorValues {
            surface: Config.tokens.system.colors.surface_elevated_hover
            content: Config.tokens.system.colors.on_surface
        }
        typography: addButton.typography
    }
}
