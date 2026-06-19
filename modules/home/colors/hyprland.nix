{ self, ... }:
let
  colors = self.lib.colors.asRgbLiterals;
in
{
  flake.homeModules.colors-hyprland = {
    wayland.windowManager.hyprland = {
      settings.config = with colors; {
        general = {
          "col.active_border" = borders_active;
          "col.inactive_border" = borders_inactive;
        };
        decoration.shadow = {
          color = shadows_active;
          color_inactive = shadows_inactive;
        };
        misc.background_color = surface_dark;
        plugin.hy3.tabs.colors = {
          "active" = surface_active;
          "inactive" = surface_inactive;
          "focused" = surface_focused_inactive;
          "urgent" = surface_urgent;
          "active_border" = borders_active;
          "inactive_border" = borders_inactive;
          "focused_border" = borders_focused_inactive;
          "urgent_border" = borders_urgent;
        };
      };
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
