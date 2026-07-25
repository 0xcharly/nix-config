{ self, inputs, ... }:
let
  inherit (inputs.nixpkgs.lib) lists;
  inherit (self.lib.theme.colors) name;
  colors = self.lib.theme.colors.asHexStrings;
in
{
  flake.homeModules.theme-ghostty =
    { lib, ... }:
    let
      font = self.lib.theme.font.terminal;
      emoji = self.lib.theme.font.emoji;
      inherit (self.lib.theme) mapFontCodepoints;
    in
    {
      programs.ghostty = {
        themes = {
          ${name} = with colors; {
            background = surface;
            foreground = text;
            selection-background = surface_visual;
            selection-foreground = on_surface_visual;
            cursor-color = surface_cursor;
            cursor-text = on_surface_cursor;
            palette = map (index: "${toString index}=${colors."terminal_color_${toString index}"}") (
              lists.range 0 15
            );
          };
        };
        settings = {
          theme = name;
          font-family = [
            font.name
            emoji.name
          ];
          font-size = font.size;
          font-feature = font.features;
          font-variation = lib.mapAttrsToList (axis: value: "${axis}=${toString value}") font.variations;
          font-codepoint-map = mapFontCodepoints (
            font_name: codepoints:
            lib.concatStringsSep "=" [
              codepoints
              font_name
            ]
          );
        };
      };
    };
}
