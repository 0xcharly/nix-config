# Theme inspired from https://github.com/catppuccin/bat
# MIT License: Copyright (c) 2021 Catppuccin

{ self, ... }:
let
  inherit (self.lib.theme.colors) name;
  colors = self.lib.theme.colors.asHexStrings;
in
{
  flake.homeModules.theme-bat =
    { pkgs, ... }:
    {
      programs.bat = {
        config.theme = name;
        themes.${name}.src =
          import ./internal/splicedpixel.tmTheme.nix { inherit name colors; }
          |> pkgs.writeText "${name}.tmTheme";
      };
    };
}
