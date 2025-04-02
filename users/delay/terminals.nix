{
  inputs,
  lib,
  pkgs,
  ...
} @ args: let
  config =
    if args ? osConfig
    then args.osConfig
    else args.config;
  inherit (config.modules.usrenv) isHeadless isLinuxDesktop;
  inherit (pkgs.stdenv) isDarwin isLinux;

  hasWindowManager = !isHeadless;
in {
  # Ghostty is installed with Homebrew on macOS.
  home.packages = lib.mkIf isLinuxDesktop (let
    pkgs' = import inputs.nixpkgs-unstable {inherit (pkgs) system;};
  in [pkgs'.ghostty]);

  # Ghostty configuration.
  xdg = lib.mkIf hasWindowManager {
    enable = true;
    configFile."ghostty/config".text =
      lib.generators.toKeyValue {
        listsAsDuplicateKeys = true;
      } ({
          font-family = ["Recursive Mono Casual Static"];
          font-size = 16;
          # https://www.recursive.design/assets/arrowtype-recursive-sansmono-specimen-230407.pdf
          font-feature = ["dlig"]; # "ss01" "ss02" "ss03" "ss04" "ss05" "ss06" "ss08" "ss11"];
          font-codepoint-map = let
            codepoints-map = {
              "mononoki" = "U+0040"; # @
              "Noto Sans Mono CJK JP" = lib.concatStringsSep "," [
                # Based off https://stackoverflow.com/a/53807563.
                # https://www.localizingjapan.com/blog/2012/01/20/regular-expressions-for-japanese-text/
                "U+3041-U+3096" # Hiragana
                "U+30A0-U+30FF" # Katakana (full width)
                "U+3400-U+4DB5,U+4E00-U+9FCB,U+F900-U+FA6A" # Kanji
                "U+2E80-U+2FD5" # Kanji radicals
                "U+FF5F-U+FF9F" # Katakana & Punctuation (half width)
                "U+3000-U+303F" # Japanese symbols & Punctuation
                "U+31F0-U+31FF,U+3220-U+3243,U+3280-U+337F" # Miscellaneous Japanese Symbols and Characters
                "U+FF01-U+FF5E" # Alphanumeric and Punctuation (full width)
              ];
            };
            gen-font-codepoint-map = family: codepoints: lib.concatStringsSep "=" [codepoints family];
          in
            lib.mapAttrsToList gen-font-codepoint-map codepoints-map;
          background = "#151b23";
          foreground = "#e1e8f4";
          selection-background = "#303747";
          selection-foreground = "#e1e8f4";
          cursor-color = "#fec49a";
          palette = [
            "0=#bac2de"
            "1=#fe9aa4"
            "2=#addba9"
            "3=#f3dfb4"
            "4=#95b7ef"
            "5=#b4befe"
            "6=#92d8d2"
            "7=#e1e8f4"
            "8=#7a8390"
            "9=#fe818d"
            "10=#8ed29c"
            "11=#f1b48e"
            "12=#89b5fa"
            "13=#d0aff8"
            "14=#71d1c7"
            "15=#90a4bb"
          ];
          background-opacity = 0.95;
          # TODO(25.05): Replace with `background-blur = true` once Ghostty 1.2 lands.
          background-blur-radius = 20;
          title = " ";
          cursor-style = "block";
          cursor-style-blink = false;
          mouse-hide-while-typing = false;
          window-padding-x = 4;
          window-padding-y = 4;
          window-padding-balance = true;
          shell-integration-features = "no-cursor,no-sudo,no-title";
          confirm-close-surface = false;
          quit-after-last-window-closed = true;
          auto-update = "off";
          keybind =
            [
              "clear"
              "super+shift+comma=reload_config"
              "shift+insert=paste_from_selection"
              "ctrl+tab=next_tab"
              "ctrl+shift+tab=previous_tab"
            ]
            ++ (let
              mod =
                if isDarwin
                then "super"
                else "ctrl";
            in [
              "${mod}+shift+n=new_window"
              "${mod}+shift+t=new_tab"
              "${mod}+shift+w=close_surface"
              "${mod}+shift+c=copy_to_clipboard"
              "${mod}+shift+v=paste_from_clipboard"
              "${mod}+equal=increase_font_size:1"
              "${mod}+minus=decrease_font_size:1"
              "${mod}+zero=reset_font_size"
              "${mod}+plus=increase_font_size:1"
            ])
            ++ lib.optionals isDarwin [
              "super+c=copy_to_clipboard"
              "super+v=paste_from_clipboard"
            ];
        }
        // (lib.optionalAttrs isLinux {gtk-titlebar = false;})
        // (lib.optionalAttrs isDarwin {macos-titlebar-proxy-icon = "hidden";}));
  };
}
