{ self, ... }:
let
  colors = self.lib.colors.asHexStrings;
  raw = self.lib.colors.noPrefix;
  # State layers / scrims: alpha byte over an opaque palette base (#AARRGGBB).
  alpha = a: c: "#${a}${c}";
in
{
  flake.homeModules.colors-arcshell = {
    programs.arcshell.settings = {
      theme = {
        hud.border.shape = 0;
      };

      tokens.system.colors = with colors; {
        on_surface = shell_on_surface;
        on_surface_dim = shell_on_surface_dim;
        on_surface_variant = shell_on_surface_variant;
        surface = shell_surface;
        wallpaper = shell_wallpaper;
        accent = accent;

        surface_elevated = alpha "1a" raw.shell_on_surface;
        surface_elevated_hover = alpha "33" raw.shell_on_surface;
        surface_backdrop = alpha "66" raw.surface_scrim;

        borders = borders;
        borders_active = borders_active;

        surface_control_slider_matrix_base = borders;
        surface_control_slider_matrix_highlight = shell_on_surface;

        on_surface_success = text_ok;

        surface_danger = surface_red;
        on_surface_danger = on_surface_red;

        surface_attention = surface_amber;
        on_surface_attention = on_surface_amber;

        surface_accent = surface_blue;
        on_surface_accent = on_surface_blue;

        surface_done = surface_purple;
        on_surface_done = on_surface_purple;

        on_surface_control_placeholder = text_dim;

        surface_control_track_rest = surface_control_track;
        surface_control_track_checked = surface_green;

        surface_control_thumb_rest = surface_control_thumb;
        on_surface_control_thumb_rest = on_surface_control_thumb;
        surface_control_thumb_checked = surface_control_thumb_checked;
        on_surface_control_thumb_checked = on_surface_control_thumb_checked;

        surface_control_thumb_hover = alpha "26" raw.surface_control_track;
        surface_control_thumb_active = alpha "33" raw.surface_control_track;
        surface_control_thumb_checked_hover = alpha "26" raw.surface_control_checked_tint;
        surface_control_thumb_checked_active = alpha "33" raw.surface_control_checked_tint;
      };
    };
  };
}
