# Theme inspired from https://github.com/catppuccin/bat
# MIT License: Copyright (c) 2021 Catppuccin

{ self, ... }:
let
  inherit (self.lib.colors) name;
  colors = self.lib.colors.asHexStrings;
in
{
  flake.homeModules.colors-bat =
    { pkgs, ... }:
    {
      programs.bat = {
        config.theme = name;
        themes.${name}.src =
          import ./_splicedpixel.tmTheme.nix { inherit name colors; }
          |> pkgs.writeText "${name}.tmTheme";
      };
    };
}
