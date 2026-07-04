import QtQuick
import Quickshell.Io
import qs.config
import qs.config.tokens.types

JsonObject {
    property int spacedBy: Config.tokens.system.measurements.none
    property PaddingValues padding: PaddingValues {
        bottom: Config.tokens.system.measurements.none
        left: Config.tokens.system.measurements.none
        right: Config.tokens.system.measurements.none
        top: Config.tokens.system.measurements.none
    }

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
}
