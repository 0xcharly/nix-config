{
  flake,
  inputs,
  ...
}:
{
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv) isDarwin isLinux;
in
{
  imports = [ inputs.nix-config-colorscheme.modules.home.ghostty ];

  programs = {
    tmux.terminal = lib.mkDefault "xterm-ghostty";

    # Ghostty configuration.
    ghostty = {
      enable = true;
      # Ghostty is installed with Homebrew on macOS.
      package = if isLinux then pkgs.ghostty else null;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      clearDefaultKeybinds = true;
      settings =
        let
          font = flake.lib.user.gui.fonts.terminal;
          inherit (flake.lib.fonts) mapFontCodepoints;
        in
        {
          font-family = [
            font.name
            "Noto Emoji" # Monochrome emojis
          ];
          font-size = font.size;
          font-feature = font.features;
          font-codepoint-map = mapFontCodepoints (
            font_name: codepoints:
            lib.concatStringsSep "=" [
              codepoints
              font_name
            ]
          );
          window-padding-x = 4;
          window-padding-y = 4;
          window-padding-balance = true;
          shell-integration-features = "no-cursor,no-title";
          confirm-close-surface = false;
          auto-update = "off";
          keybind = [
            "super+shift+comma=reload_config"
            "shift+insert=paste_from_selection"
            "ctrl+tab=next_tab"
            "ctrl+shift+tab=previous_tab"
          ]
          ++ (
            let
              mod = if isDarwin then "super" else "ctrl";
            in
            [
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
            ]
          )
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
