# Theme inspired from https://github.com/catppuccin/bat
# MIT License: Copyright (c) 2021 Catppuccin

{ self, ... }:
let
  inherit (self.lib.colors) name;
in
{
  flake.homeModules.colors-bat = {
    programs.bat = {
      config.theme = name;
      # TODO: Create theme file from template.
      themes.${name}.src = ./pixel.tmTheme;
    };
  };
}
