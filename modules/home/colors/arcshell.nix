{ self, ... }:
let
  colors = self.lib.colors.asHexStrings;
in
{
  flake.homeModules.colors-arcshell = {
    programs.arcshell.settings.palette = with colors; {
      text = text_variant_dim;
      surface = surface;
      inner_border = borders_desktop_shell;
      inner_border_shadow = shadows_desktop_shell;

      surface_red = surface_red;
      on_surface_red = on_surface_red;

      surface_orange = surface_amber;
      on_surface_orange = on_surface_amber;

      surface_blue = surface_blue;
      on_surface_blue = on_surface_blue;

      surface_purple = surface_violet;
      on_surface_purple = on_surface_violet;

      slider_active_track = on_surface_violet;
      slider_inactive_track = surface_violet;
      slider_thumb = on_surface_violet;
    };
  };
}
