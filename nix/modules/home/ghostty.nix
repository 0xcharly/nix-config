{flake, ...}: {
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv) isDarwin isLinux;
in {
  programs = {
    tmux.terminal = lib.mkDefault "xterm-ghostty";

    # Ghostty configuration.
    ghostty = {
      enable = true;
      # Ghostty is installed with Homebrew on macOS.
      package =
        if isLinux
        then pkgs.ghostty
        else null;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      themes = {
        catppuccin-obsidian = {
          background = "#10141e";
          foreground = "#cad5e2";
          selection-background = "#303747";
          selection-foreground = "#e1e8f4";
          cursor-color = "#bac2de";
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
        };
      };
      clearDefaultKeybinds = true;
      settings = let
        font = flake.lib.user.gui.fonts.terminal;
      in
        {
          font-family = [
            font.name
            "Noto Emoji" # Monochrome emojis
          ];
          font-size = font.size;
          font-feature = font.features;
          font-codepoint-map = let
            mkCodepointList = lib.concatStringsSep ",";
            codepoints-map = {
              # Based off https://stackoverflow.com/a/53807563.
              # https://www.localizingjapan.com/blog/2012/01/20/regular-expressions-for-japanese-text/
              "Noto Sans Mono CJK JP" = mkCodepointList [
                "U+3041-U+3096" # Hiragana
                "U+30A0-U+30FF" # Katakana (full width)
                "U+3400-U+4DB5,U+4E00-U+9FCB,U+F900-U+FA6A" # Kanji
                "U+2E80-U+2FD5" # Kanji radicals
                "U+FF5F-U+FF9F" # Katakana & Punctuation (half width)
                "U+3000-U+303F" # Japanese symbols & Punctuation
                "U+31F0-U+31FF,U+3220-U+3243,U+3280-U+337F" # Miscellaneous Japanese Symbols and Characters
                "U+FF01-U+FF5E" # Alphanumeric and Punctuation (full width)
              ];
              "Noto Emoji" = let
                inherit (builtins.fromTOML (builtins.readFile ./emoji.toml)) codepoints;
              in
                mkCodepointList codepoints;
              # https://github.com/ryanoasis/nerd-fonts/wiki/Glyph-Sets-and-Code-Points#material-design-icons
              "Material Design Icons" = mkCodepointList [
                "U+F0001-U+F1AF0" # Material Design Icons
              ];
              # https://github.com/ryanoasis/nerd-fonts/wiki/Glyph-Sets-and-Code-Points
              "Symbols Nerd Font" = mkCodepointList [
                "U+E5FA-U+E6B7" # Seti-UI + Custom
                "U+E700-U+E8EF" # Devicons
                "U+ED00-U+F2FF" # Font Awesome
                "U+E200-U+E2A9" # Font Awesome extension
                "U+E300-U+E3E3" # Weather
                "U+F400-U+F533,U+2665,U+26A1" # Octicons
                "U+23FB-U+23FE,U+2B58" # IEC Power Symbols
                "U+F300-U+F381" # Font Logos
                "U+E000-U+E00A" # Pomicons
                "U+EA60-U+EC1E" # Codeicons
              ];
              # https://github.com/ryanoasis/nerd-fonts/wiki/Glyph-Sets-and-Code-Points#powerline-symbols
              ${font.name} = mkCodepointList [
                "U+E0A0-U+E0A2,U+E0B0-U+E0B3" # Powerline Symbols
                "U+E0A3,U+E0B4-U+E0C8,U+E0CA,U+E0CC-U+E0D7,U+2630" # Powerline Extra Symbols
                "U+276C-U+2771" # Heavy Angle Brackets
                "U+2500-U+259F" # Box Drawing
                "U+EE00-U+EE0B" # Progress
              ];
            };
            gen-font-codepoint-map = family: codepoints: lib.concatStringsSep "=" [codepoints family];
          in
            lib.mapAttrsToList gen-font-codepoint-map codepoints-map;
          theme = "catppuccin-obsidian";
          window-padding-x = 4;
          window-padding-y = 4;
          window-padding-balance = true;
          shell-integration-features = "no-cursor,no-title";
          confirm-close-surface = false;
          auto-update = "off";
          keybind =
            [
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
              "${mod}+shift+n=new_window" # Prevents conflicts with harpoon.
              "${mod}+shift+t=new_tab" # Prevents conflicts with harpoon.
              "${mod}+shift+w=close_surface"
              "${mod}+shift+c=copy_to_clipboard"
              "${mod}+shift+v=paste_from_clipboard"
              "${mod}+equal=increase_font_size:1"
              "${mod}+minus=decrease_font_size:1"
              "${mod}+zero=reset_font_size"
              "${mod}+plus=increase_font_size:1"
              "${mod}+backspace=text:\\x17" # Delete word.
              "${mod}+delete=text:\\x15" # Delete line.
            ])
            ++ lib.optionals isDarwin [
              "super+c=copy_to_clipboard"
              "super+v=paste_from_clipboard"
            ];
        }
        // lib.optionalAttrs isLinux {
          gtk-single-instance = true;
          gtk-titlebar = false;
        }
        // lib.optionalAttrs isDarwin {
          macos-titlebar-proxy-icon = "hidden";
        };
    };
  };
}
