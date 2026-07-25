{ self, inputs, ... }:
let
  inherit (inputs.nixpkgs.lib) concatStringsSep lists;
  inherit (self.lib.theme.colors) name;
  colors = self.lib.theme.colors.asHexStrings;
in
{
  flake.homeModules.theme-kitty =
    { lib, pkgs, ... }:
    let
      font = self.lib.theme.font.terminal;
      inherit (self.lib.theme) mapFontCodepoints;
      # Harfbuzz feature syntax: "+tag" enables, "tag=N" selects a value.
      # "+tag=N" is invalid, so only prefix "+" on value-less tags.
      font-features = lib.concatStringsSep " " (
        map (feat: if lib.hasInfix "=" feat then feat else "+${feat}") font.features
      );
      font-variations = lib.concatStringsSep " " (
        lib.mapAttrsToList (axis: value: "${axis}=${toString value}") font.variations
      );
      font-family = concatStringsSep " " (
        [
          "font_family"
          ''family="${font.name}"''
        ]
        ++ lib.optional (font.variations != { }) font-variations
        ++ lib.optional (font.features != [ ]) ''features="${font-features}"''
      );
      symbol-maps = mapFontCodepoints (font_name: codepoints: "symbol_map ${codepoints} ${font_name}");
      content =
        with colors;
        ''
          # Typography
          font_size ${toString font.size}
          ${font-family}

          ${concatStringsSep "\n" symbol-maps}

          # Basic colors
          background ${surface}
          foreground ${text}
          selection_background ${surface_visual}
          selection_foreground ${on_surface_visual}
          cursor ${surface_cursor}
          cursor_text_color ${on_surface_cursor}
          url_color ${text_link}

          # 16 terminal colors
        ''
        + concatStringsSep "\n" (
          map (index: "color${toString index} ${colors."terminal_color_${toString index}"}") (
            lists.range 0 15
          )
        );
    in
    {
      programs.kitty.extraConfig = ''
        include ${pkgs.writeText "${name}.conf" content}
      '';
    };
}
