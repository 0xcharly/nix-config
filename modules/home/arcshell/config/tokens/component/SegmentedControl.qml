import QtQuick
import Quickshell.Io
import qs.config
import qs.config.tokens.types

JsonObject {
    // Outer container.
    property int shape: Config.tokens.system.shapes.cornerFull
    // Same surface as theme.defaults.cards (translucent backdrop).
    property SurfaceColorValues colors: SurfaceColorValues {
        surface: Config.tokens.system.colors.surface_backdrop
        content: Config.tokens.system.colors.on_surface_variant
    }

    // Moving selector behind the active segment.
    // selectorPadding = gap between the outer container edge and the selector.
    property int selectorPadding: Config.tokens.system.measurements.extraSmall
    // Default selector shape is concentric with the outer shape (outer - padding).
    // cornerFull (1000) needs no special-casing: Rectangle clamps radius to half
    // the item height, so `full - padding` still renders as a pill on the
    // selector and equals the resolved `min(shape, height/2) - padding` exactly
    // (in-repo precedent: the workspaces indicator renders cornerFull chips).
    property int selectorShape: shape - selectorPadding
    // Selector reuses the backdrop surface: it stacks on the container, so
    // the alpha values combine into a brighter pill without a second tone.
    property SurfaceColorValues selected: SurfaceColorValues {
        surface: Config.tokens.system.colors.surface_backdrop
        content: Config.tokens.system.colors.on_surface
    }
    // Hover: backdrop layer over an unselected segment; stacks on the
    // container surface the same way the selector does.
    property color hoverLayer: Config.tokens.system.colors.surface_backdrop
    // Selector slide: same default as the workspaces indicator
    // (feature/Workspaces.qml `animation: AnimationValues {}` — standard
    // curve, medium duration).
    property AnimationValues animation: AnimationValues {}
    // Gap between segments; keeps the selector pill visually separated
    // from a hovered neighbor's layer.
    property int spacing: Config.tokens.system.measurements.extraSmall

    // Per-segment content (icon + label row).
    property PaddingValues segmentPadding: PaddingValues {
        bottom: Config.tokens.system.measurements.small
        left: Config.tokens.system.measurements.medium
        right: Config.tokens.system.measurements.medium
        top: Config.tokens.system.measurements.small
    }
    property int segmentSpacing: Config.tokens.system.measurements.small
    property TypographyValues typography: Config.tokens.system.typography.smallTitle
    property TypographyValues iconTypography: Config.tokens.system.typography.icon
}
