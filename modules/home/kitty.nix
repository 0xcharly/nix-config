{ flake, inputs, ... }:
{ lib, ... }:
{
  imports = [ inputs.nix-config-colorscheme.modules.home.kitty ];

  programs = {
    tmux.terminal = "xterm-kitty";

    kitty =
      let
        font = flake.lib.user.gui.fonts.variable.mono;
        inherit (flake.lib.fonts) mapFontCodepoints;
      in
      {
        enable = true;
        shellIntegration = {
          enableBashIntegration = true;
          enableZshIntegration = true;
          enableFishIntegration = true;
        };
        extraConfig =
          let
            font-features = font.features |> map (feat: "+${feat}") |> lib.concatStringsSep " ";
            font-variations =
              font.variations |> lib.mapAttrsToList (axis: value: "${axis}=${toString value}") |> lib.concatStringsSep " ";
            symbol-maps = mapFontCodepoints (font_name: codepoints: "symbol_map ${codepoints} ${font_name}");
          in
          ''
            font_size ${toString font.size}
            font_family family=${font.name} ${font-variations} features="${font-features}"

            window_padding_width 4
            confirm_os_window_close 0

            ${lib.concatStringsSep "\n" symbol-maps}
          '';
      };
  };
}
