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
  inherit (pkgs.stdenv) isDarwin isLinux;

  hasWindowManager = !isHeadless;
in {
  home.packages = lib.mkIf (isLinux && hasWindowManager) [
    # Ghostty is installed with Homebrew on macOS.
    pkgs.ghostty
  ];

  # Ghostty configuration.
  xdg = lib.mkIf hasWindowManager {
    enable = true;
    configFile."ghostty/config".text =
      lib.generators.toKeyValue {
        listsAsDuplicateKeys = true;
      } ({
          font-family = ["Comic Code Ligatures"];
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
          # custom-shader = pkgs.writeTextFile {
          #   name = "custom-shader.glsl";
          #   text = builtins.readFile ./ghostty/glow-rgbsplit-twitchy.glsl;
          # };
          # custom-shader-animation = false;
          theme = "catppuccin-mocha";
          background = "#1d1f21"; # Gunmetal background (darker than Catppuccin Mocha)
          selection-background = "#212a37";
          title = " ";
          cursor-style = "block";
          cursor-style-blink = false;
          mouse-hide-while-typing = false;
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
              "${mod}+n=new_window"
              "${mod}+t=new_tab"
              "${mod}+shift+c=copy_to_clipboard"
              "${mod}+shift+v=paste_from_clipboard"
              "${mod}+equal=increase_font_size:1"
              "${mod}+minus=decrease_font_size:1"
              "${mod}+zero=reset_font_size"
              "${mod}+plus=increase_font_size:1"
            ]);
        }
        // (lib.optionalAttrs isLinux {
          gtk-titlebar = false;
          font-size = 13;
        })
        // (lib.optionalAttrs isDarwin {
          macos-titlebar-proxy-icon = "hidden";
          font-size = 14;
        }));
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
