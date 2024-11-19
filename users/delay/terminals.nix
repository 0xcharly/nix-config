{
  pkgs,
  lib,
  ...
} @ args: let
  config =
    if args ? osConfig
    then args.osConfig
    else args.config;
  inherit (config.modules.usrenv) isHeadless;
  inherit (pkgs.stdenv) isDarwin;

  hasWindowManager = !isHeadless;
in {
  # Ghostty configuration.
  xdg = {
    enable = true;
    configFile = {
      "ghostty/config".text =
        lib.generators.toKeyValue {
          listsAsDuplicateKeys = true;
        } ({
            font-family = ["Comic Code Ligatures"];
            font-size = 14;
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
            custom-shader = pkgs.writeTextFile {
              name = "tft.glsl";
              text = builtins.readFile ./tft.glsl;
            };
            custom-shader-animation = false;
            theme = "catppuccin-mocha";
            cursor-style = "block";
            cursor-style-blink = false;
            mouse-hide-while-typing = false;
            window-padding-balance = true;
            title = "‎";
            keybind = "super+shift+comma=reload_config";
            shell-integration-features = "no-cursor,no-sudo,no-title";
            confirm-close-surface = false;
            quit-after-last-window-closed = true;
            auto-update = "off";
          }
          // (lib.optionalAttrs isDarwin {
            adjust-cell-height = "-15%"; # Comic Code is a little tall by default on macOS.
          }));
    };
  };

  # Alacritty configuration.
  programs.alacritty = lib.mkIf hasWindowManager {
    enable = true;
    catppuccin.enable = true;
    settings = {
      font = {
        normal = {
          family = "IosevkaTerm Nerd Font";
          style = "Light";
        };
        bold = {
          family = "IosevkaTerm Nerd Font";
          style = "Medium";
        };
        size = 16;
      };
      keyboard.bindings = lib.optionals isDarwin [
        {
          key = "Tab";
          mods = "Control";
          action = "SelectNextTab";
        }
        {
          key = "Tab";
          mods = "Control|Shift";
          action = "SelectPreviousTab";
        }
      ];
      window = {
        decorations = "Full";
        padding = {
          x = 4;
          y = 4;
        };
      };
    };
  };
}
