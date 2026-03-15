{ flake, inputs, ... }:
{ lib, pkgs', ... }:
let
  inherit (pkgs'.stdenv) isDarwin isLinux;
  package = if isLinux then pkgs'.ghostty else pkgs'.ghostty-bin;
in
{
  imports = [ inputs.nix-config-colorscheme.modules.home.ghostty ];

  programs.ghostty = {
    enable = true;
    inherit package;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    clearDefaultKeybinds = true;
    settings =
      let
        inherit (flake.lib.fonts) mapFontCodepoints;
        inherit (flake.lib.user.gui) fonts;
        font = fonts.terminal;
      in
      {
        font-family = [
          font.name
          fonts.emoji.name
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
        window-padding-x = 2;
        window-padding-y = 2;
        window-padding-balance = true;
        window-padding-color = "extend";
        unfocused-split-opacity = 1;
        shell-integration-features = "no-cursor,no-title";
        notify-on-command-finish = "unfocused";
        notify-on-command-finish-action = "no-bell,notify";
        confirm-close-surface = false;
        auto-update = "off";
        custom-shader = "${./ghostty-cursor-trail.glsl}";
        adjust-cursor-thickness = 2;
        keybind = [
          "super+shift+comma=reload_config"
          "ctrl+tab=next_tab"
          "ctrl+shift+tab=previous_tab"

          "ctrl+shift+h=goto_split:left"
          "ctrl+shift+j=goto_split:bottom"
          "ctrl+shift+k=goto_split:top"
          "ctrl+shift+l=goto_split:right"

          "ctrl+a>h=new_split:left"
          "ctrl+a>j=new_split:down"
          "ctrl+a>k=new_split:up"
          "ctrl+a>l=new_split:right"
          "ctrl+a>f=toggle_split_zoom"

          "ctrl+a>n=next_tab"
          "ctrl+a>p=previous_tab"
        ]
        ++ (
          let
            mod = if isDarwin then "super" else "ctrl";
          in
          [
            "${mod}+n=new_window"
            "${mod}+t=new_tab"
            "${mod}+shift+t=toggle_tab_overview"
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
        window-show-tab-bar = "never";
      }
      // lib.optionalAttrs isDarwin {
        macos-titlebar-proxy-icon = "hidden";
      };
  };
}
