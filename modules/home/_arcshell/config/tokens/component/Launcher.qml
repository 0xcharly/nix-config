import QtQuick
import Quickshell.Io
import qs.config
import qs.config.tokens.types

JsonObject {
    // Dimensions
    property int width: 512
    property int maxHeight: 360
    property int lineWidth: 2
    // Distance each border line extends past the panel corner, per line end.
    property int lineOvershoot: 16
    // Length of the fade-to-transparent gradient at each line end.
    property int lineFade: 16
    property int spacedBy: Config.tokens.system.measurements.small
    property PaddingValues padding: PaddingValues {
        bottom: Config.tokens.system.measurements.medium
        left: Config.tokens.system.measurements.medium
        right: Config.tokens.system.measurements.medium
        top: Config.tokens.system.measurements.medium
    }

    // Colors
    property color lineColor: Config.tokens.system.colors.on_surface
    property SurfaceColorValues colors: SurfaceColorValues {
        surface: Config.tokens.system.colors.surface
        content: Config.tokens.system.colors.on_surface
    }

    // Typography
    property TypographyValues titleTypography: Config.tokens.system.typography.mediumLabel
    property color titleContentColor: Config.tokens.system.colors.on_surface_variant

    // Input field
    property SurfaceTokens input: SurfaceTokens {
        colors: SurfaceColorValues {
            surface: Config.tokens.system.colors.wallpaper
            content: Config.tokens.system.colors.on_surface
        }
        padding: PaddingValues {
            left: Config.tokens.system.measurements.medium
            right: Config.tokens.system.measurements.medium
        }
        shape: Config.tokens.system.shapes.cornerSmall
        typography: Config.tokens.system.typography.body
    }
    property color inputPlaceholderColor: Config.tokens.system.colors.on_surface_control_placeholder

    // Input field (fixed row height now that results sit below it)
    property int inputHeight: 44

    // Results list
    property int resultRowHeight: 40
    property TypographyValues resultTypography: Config.tokens.system.typography.body
    property color resultContentColor: Config.tokens.system.colors.on_surface
    property SurfaceColorValues resultSelected: SurfaceColorValues {
        surface: Config.tokens.system.colors.surface_accent
        content: Config.tokens.system.colors.on_surface_accent
    }
    property int resultShape: Config.tokens.system.shapes.cornerSmall

    // Leading result cell: rounded box behind app icons and the bin-mode
    // terminal glyph, so low-contrast/transparent app icons sit on a
    // readable backdrop. Same accent pair as the active workspace chip.
    // The box size is the sizing knob; the inner icon renders at 2/3 of it.
    property int resultIconBoxSize: 32
    property int resultIconBoxShape: Config.tokens.system.shapes.cornerSmall
    property SurfaceColorValues resultIconBox: SurfaceColorValues {
        surface: Config.tokens.system.colors.surface_accent
        content: Config.tokens.system.colors.on_surface_accent
    }

    // Animations. `duration` spans the whole two-phase open/close. The
    // wrapper clamps its per-phase progress at 1, so an overshooting
    // (spatial/spring) curve here reads as dead time at the end of the
    // open — keep these curves monotonic. Open runs the time-reverse of
    // the close curve: a slow build that lingers on the phase-1 line
    // sweep, then a fast finish — the tube warming up before the picture
    // snaps in.
    property AnimationValues animation: AnimationValues {
        curveIn: Config.tokens.system.animations.curves.emphasizedIn
        curveOut: Config.tokens.system.animations.curves.emphasizedOut
        duration: Config.tokens.system.animations.durations.medium
    }
    // Share of the open/close spent sweeping the horizontal border line
    // out from the center; the rest parts the borders to reveal the
    // content. Lower = snappier line, longer reveal.
    property real lineSweepFraction: 0.4
}
