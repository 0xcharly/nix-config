{ self, ... }:
let
  colors = self.lib.colors.asRgbLiterals;
in
{
  flake.homeModules.colors-hyprland = {
    wayland.windowManager.hyprland = {
      settings.config = with colors; {
        general = {
          border_size = 1;
          gaps_in = 2;
          gaps_out = 6;
          "col.active_border" = borders_active;
          "col.inactive_border" = borders_inactive;
        };
        decoration = {
          rounding = 0;
          blur.enabled = false;
          shadow.enabled = false;
        };
        misc.background_color = surface_dark;
        plugin.hy3.tabs = {
          blur = false;
          border_width = 0;
          height = 18;
          padding = 0;
          radius = 0;
          colors = {
            active = surface_active;
            active_border = borders_active;
            active_text = surface;

            active_alt_monitor = surface_active;
            active_alt_monitor_border = borders_active;
            active_alt_monitor_text = surface;

            inactive = surface_inactive;
            inactive_border = borders_inactive;
            inactive_text = surface_active;

            focused = surface_focused_inactive;
            focused_border = borders_focused_inactive;

            urgent = surface_urgent;
            urgent_border = borders_urgent;
          };
        };
      };
    };

    programs.hyprlock.settings = {
      general = {
        hide_cursor = true;
        no_fade_in = false;
      };

      background = [
        {
          path = "screenshot";
          blur_passes = 3;
          blur_size = 8;
        }
      ];

      input-field = [
        {
          size = "720, 96";
          position = "0, 0";
          dots_center = true;
          dots_size = 0.2;
          dots_spacing = 0.4;
          fade_on_empty = false;
          font_color = "rgba(225, 232, 244, 1)";
          inner_color = "rgba(29, 37, 48, 1)";
          outer_color = "rgba(29, 41, 56, 1)";
          check_color = "rgba(137, 180, 250, 1)";
          fail_color = "rgba(254, 154, 164, 1)";
          outline_thickness = 2;
          placeholder_text = "<i><span foreground=\"##bac2deff\">×͜×</span></i>";
          shadow_passes = 0;
        }
      ];
    };

    xdg.configFile."hypr/hyprtoolkit.conf".text = with colors; ''
      background = ${surface}
      base = ${surface_cursorline}
      text = ${text}
      alternate_base = ${surface_menu}
      bright_text = ${text_title}
      accent = ${accent_darker}
      accent_secondary = ${accent_secondary_darker}
      h1_size = 18
      h2_size = 16
      h3_size = 13
      font_size = 12
      small_font_size = 11
      rounding_large = 8
      rounding_small = 6
    '';
  };
}
