import QtQuick
import Quickshell.Io
import qs.config
import qs.config.tokens.types

JsonObject {
    property color trackColorRest: Config.tokens.system.colors.surface_control_track_rest
    property color trackColorChecked: Config.tokens.system.colors.surface_control_track_checked

    property SurfaceColorValues thumbColorRest: SurfaceColorValues {
        surface: Config.tokens.system.colors.surface_control_thumb_rest
        content: Config.tokens.system.colors.on_surface_control_thumb_rest
    }
    property SurfaceColorValues thumbColorActive: SurfaceColorValues {
        surface: Config.tokens.system.colors.surface_control_thumb_active
        content: Config.theme.defaults.switches.thumbColorRest.content
    }
    property SurfaceColorValues thumbColorHover: SurfaceColorValues {
        surface: Config.tokens.system.colors.surface_control_thumb_hover
        content: Config.theme.defaults.switches.thumbColorRest.content
    }
    property SurfaceColorValues thumbColorChecked: SurfaceColorValues {
        surface: Config.tokens.system.colors.surface_control_thumb_checked
        content: Config.tokens.system.colors.on_surface_control_thumb_checked
    }
    property SurfaceColorValues thumbColorCheckedActive: SurfaceColorValues {
        surface: Config.tokens.system.colors.surface_control_thumb_checked_active
        content: Config.theme.defaults.switches.thumbColorChecked.content
    }
    property SurfaceColorValues thumbColorCheckedHover: SurfaceColorValues {
        surface: Config.tokens.system.colors.surface_control_thumb_checked_hover
        content: Config.theme.defaults.switches.thumbColorChecked.content
    }

    property int thumbSize: 22
    property PaddingValues thumbPadding: PaddingValues {
        bottom: Config.tokens.system.measurements.extraSmall
        left: Config.tokens.system.measurements.extraSmall
        right: Config.tokens.system.measurements.extraSmall
        top: Config.tokens.system.measurements.extraSmall
    }

    property real iconStrokeWidth: 2.25
    property PaddingValues iconPadding: PaddingValues {
        bottom: Config.tokens.system.measurements.extraSmall
        left: Config.tokens.system.measurements.extraSmall
        right: Config.tokens.system.measurements.extraSmall
        top: Config.tokens.system.measurements.extraSmall
    }

    property AnimationValues animation: AnimationValues {}
}
