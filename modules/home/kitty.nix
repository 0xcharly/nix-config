{
  flake,
  inputs,
  ...
}:
{ lib, ... }:
{
  imports = [ inputs.nix-config-colorscheme.modules.home.kitty ];

  programs = {
    tmux.terminal = "xterm-kitty";

    kitty =
      let
        font = flake.lib.user.gui.fonts.terminal;
        inherit (flake.lib.fonts) mapFontCodepoints;
      in
      {
        enable = true;
        font = { inherit (font) name size; };
        shellIntegration = {
          enableBashIntegration = true;
          enableZshIntegration = true;
          enableFishIntegration = true;
        };
        extraConfig =
          let
            symbol_maps = mapFontCodepoints (font_name: codepoints: "symbol_map ${codepoints} ${font_name}");
          in
          ''
            font_features PragmataProMonoLiga-Regular ${
              lib.concatStringsSep " " (map (f: "+${f}") font.features)
            }
            font_features PragmataProMonoLiga-Bold ${lib.concatStringsSep " " (map (f: "+${f}") font.features)}
            font_features PragmataProMonoLiga-Italic ${
              lib.concatStringsSep " " (map (f: "+${f}") font.features)
            }
            font_features PragmataProMonoLiga-BoldItalic ${
              lib.concatStringsSep " " (map (f: "+${f}") font.features)
            }
            text_composition_strategy 0.5 0

            window_padding_width 4
            confirm_os_window_close 0

            ${lib.concatStringsSep "\n" symbol_maps}
          '';
      };
  };
}
