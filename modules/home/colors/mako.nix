# Theme inspired from https://github.com/catppuccin/mako
# MIT License: Copyright (c) 2021 Catppuccin

{ self, ... }:
let
  colors = self.lib.colors.asHexStrings;
in
{
  flake.homeModules.colors-mako = {
    config.services.mako.settings = with colors; {
      background-color = surface;
      text-color = text;
      border-color = text_blue;
      progress-color = surface_cursorline;

      "urgency=high".border-color = text_red;
    };
  };
}
