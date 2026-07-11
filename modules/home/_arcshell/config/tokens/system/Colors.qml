import QtQuick
import Quickshell.Io

// No palette defaults on purpose: every token is set from Nix
// (modules/home/colors/arcshell.nix) through shell.json. A missing override
// resolves to an invalid QColor and renders visibly broken — fix the Nix
// mapping, do not add a default here.
JsonObject {
    property color transparent: "#00000000"

    property color on_surface
    property color on_surface_dim
    property color on_surface_variant
    property color surface
    property color wallpaper
    property color accent
    property color surface_elevated
    property color surface_elevated_hover

    property color borders
    property color borders_active

    property color surface_control_slider_matrix_base
    property color surface_control_slider_matrix_highlight

    property color on_surface_success

    property color surface_danger
    property color on_surface_danger

    property color surface_attention
    property color on_surface_attention

    property color surface_accent
    property color on_surface_accent

    property color surface_done
    property color on_surface_done

    property color surface_backdrop

    property color on_surface_control_placeholder

    property color surface_control_track_rest
    property color surface_control_track_checked

    property color on_surface_control_thumb_rest
    property color surface_control_thumb_rest
    property color surface_control_thumb_checked
    property color on_surface_control_thumb_checked

    property color surface_control_thumb_active
    property color surface_control_thumb_hover
    property color surface_control_thumb_checked_active
    property color surface_control_thumb_checked_hover
}
