{ self, inputs, ... }:
let
  inherit (inputs.nixpkgs.lib) lists;
  inherit (self.lib.colors) name;
  colors = self.lib.colors.asHexStrings;
in
{
  flake.homeModules.colors-ghostty = {
    programs.ghostty = {
      themes = {
        ${name} = with colors; {
          background = surface;
          foreground = text;
          selection-background = surface_visual;
          selection-foreground = on_surface_visual;
          cursor-color = surface_cursor;
          palette = map (index: "${toString index}=${colors."terminal_color_${toString index}"}") (
            lists.range 0 15
          );
        };
      };
      settings.theme = name;
    };
  };
}
