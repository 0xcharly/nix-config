{ flake, inputs, ... }:
{ lib, ... }:
{
  imports = [ inputs.nix-config-colorscheme.homeModules.kitty ];

  programs.kitty =
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
          font-features = lib.concatStringsSep " " (map (feat: "+${feat}") font.features);
          font-variations = lib.concatStringsSep " " (
            lib.mapAttrsToList (axis: value: "${axis}=${toString value}") font.variations
          );
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
}
