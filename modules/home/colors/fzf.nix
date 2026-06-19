# Theme inspired from https://github.com/catppuccin/fzf
# MIT License: Copyright (c) 2022 Catppuccin

{ self, ... }:
let
  colors = self.lib.colors.asHexStrings;
in
{
  flake.homeModules.colors-fzf = {
    programs.fzf.colors = with colors; {
      "bg+" = surface_cursorline;
      "fg+" = text_title;
      "hl+" = text_sky;
      bg = surface;
      border = borders;
      disabled = text_variant_dimmer;
      fg = text;
      gutter = surface;
      header = text_cyan;
      hl = text_blue;
      info = text_amber;
      marker = text_emerald;
      pointer = text_violet;
      prompt = text_blue;
      query = text;
      separator = borders;
      spinner = text_violet;
    };
  };
}
