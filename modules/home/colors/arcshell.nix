{ self, ... }:
let
  colors = self.lib.colors.asHexStrings;
in
{
  flake.homeModules.colors-arcshell = {
    programs.arcshell.settings = {
      theme = {
        hud.border.shape = 0;
      };

      tokens.system.colors = with colors; {
        on_surface = shell_on_surface;
        on_surface_variant = shell_on_surface_variant;
        surface = shell_surface;
        wallpaper = shell_wallpaper;

        borders = borders;
        borders_active = borders_active;

        surface_danger = surface_red;
        on_surface_danger = on_surface_red;

        surface_attention = surface_amber;
        on_surface_attention = on_surface_amber;

        surface_accent = surface_blue;
        on_surface_accent = on_surface_blue;

        surface_done = surface_purple;
        on_surface_done = on_surface_purple;
      };
    };
  };
}
