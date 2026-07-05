import QtQuick
import Quickshell.Io

// Defaults from https://primer.style/primitives/storybook/
JsonObject {
    property color transparent: "#00000000"

    property color on_surface: "#d4d4d8" // zinc-300
    property color on_surface_dim: "#a1a1aa" // zinc-400
    property color on_surface_variant: "#71717a" // zinc-500
    property color surface: "#090b0c" // zinc-950
    property color wallpaper: "#18181b" // zinc-900

    property color borders: "#52525b" // zinc-600
    property color borders_active: "#52525b" // zinc-600

    property color surface_control_slider_matrix_base: borders
    property color surface_control_slider_matrix_highlight: on_surface

    property color on_surface_success: "#4ade80" // green-400

    property color surface_danger: "#1af87171" // red-400 @ 10%
    property color on_surface_danger: "#f87171" // red-400

    property color surface_attention: "#26fb923c" // orange-400 @ 38%
    property color on_surface_attention: "#fb923c" // orange-400

    property color surface_accent: "#1a60a5fa" // blue-400 @ 10%
    property color on_surface_accent: "#60a5fa" // blue-400

    property color surface_done: "#26a78bfa" // violet-400 @ 38%
    property color on_surface_done: "#a78bfa" // violet-400

    property color surface_backdrop: "#66212830" // overlay-backdrop-bgColor

    property color on_surface_control_placeholder: "#9198a1" // control-fgColor-placeholder

    property color surface_control_track_rest: "#262c36" // controlTrack-bgColor-rest
    property color surface_control_track_checked: "#262ea043" // bgColor-success-muted

    property color on_surface_control_thumb_rest: "#262c36" // bgColor-neutral-muted
    property color surface_control_thumb_rest: "#656c76" // bgColor-neutral-emphasis
    property color surface_control_thumb_checked: "#238636" // bgColor-success-emphasis
    property color on_surface_control_thumb_checked: "#1e3226" // bgColor-success-muted

    property color surface_control_thumb_active: "#332a313c" // control-bgColor-active
    property color surface_control_thumb_hover: "#26262c36" // control-bgColor-hover
    property color surface_control_thumb_checked_active: "#332ea043"
    property color surface_control_thumb_checked_hover: "#262ea043" // bgColor-success-muted

    property color surface_control_slider_active_track: "#1d4ed8" // blue-700
    property color surface_control_slider_inactive_track: "#1a3b82f6" // blue-500 @ 10%
    property color surface_control_slider_thumb: "#3b82f6" // blue-500
}
