{ self, inputs, ... }:
let
  inherit (inputs.nixpkgs.lib) concatStringsSep lists;
  colors = self.lib.colors.asHexStrings;
in
{
  flake.homeModules.colors-kitty =
    { pkgs, ... }:
    let
      content =
        with colors;
        ''
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
        include ${pkgs.writeText "pixel.conf" content}
      '';
    };
}
