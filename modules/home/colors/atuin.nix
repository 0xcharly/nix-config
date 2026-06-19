# Theme inspired from https://github.com/catppuccin/atuin
# MIT License: Copyright (c) 2021 Catppuccin

{ self, ... }:
let
  inherit (self.lib.colors) name;
  colors = self.lib.colors.asHexStrings;
in
{
  flake.homeModules.colors-atuin =
    { pkgs, ... }:
    {
      programs.atuin.settings.theme.name = name;
      xdg.configFile."atuin/themes/${name}.toml".source =
        (pkgs.formats.toml { }).generate "${name}.theme"
          {
            theme.name = name;
            colors = with colors; {
              AlertError = text_error;
              AlertInfo = text_ok;
              AlertWarn = text_warning;
              Annotation = text_info;
              Base = text;
              Guidance = text_comment;
              Important = text_red;
              Title = text_title;
            };
          };
    };
}
