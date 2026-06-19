{ self, ... }:
{
  flake.homeModules.programs-ghostty =
    { lib, ... }:
    {
      imports = [ self.homeModules.colors-ghostty ];

      programs.ghostty = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
        enableFishIntegration = true;
        clearDefaultKeybinds = true;
        settings =
          let
            inherit (self.lib.fonts) mapFontCodepoints;
            inherit (self.lib.user.gui) fonts;
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
            window-inherit-working-directory = false;
            window-show-tab-bar = "never";
            tab-inherit-working-directory = true;
            split-inherit-working-directory = true;
            unfocused-split-opacity = 1;
            shell-integration-features = "no-cursor,no-title";
            notify-on-command-finish = "unfocused";
            notify-on-command-finish-action = "no-bell,notify";
            confirm-close-surface = false;
            auto-update = "off";
            adjust-cursor-thickness = 1;
            keybind = [
              "super+shift+comma=reload_config"
              "super+k=toggle_command_palette"
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

              "ctrl+a>alt+2=goto_tab:1"
              "ctrl+a>alt+3=goto_tab:2"
              "ctrl+a>alt+4=goto_tab:3"
              "ctrl+a>alt+5=goto_tab:4"

              "ctrl+a>/=start_search"
              "ctrl+a>shift+8=search_selection"

              "ctrl+a>n=next_tab"
              "ctrl+a>p=previous_tab"
              "ctrl+n=new_window"
              "ctrl+t=last_tab"
              "chain=new_tab"
              "ctrl+shift+t=toggle_tab_overview"
              "ctrl+shift+w=close_surface"
              "ctrl+shift+c=copy_to_clipboard"
              "ctrl+shift+v=paste_from_clipboard"
              "ctrl+equal=increase_font_size:1"
              "ctrl+minus=decrease_font_size:1"
              "ctrl+zero=reset_font_size"
              "ctrl+plus=increase_font_size:1"
              "ctrl+backspace=text:\\x17" # Delete word.
              "ctrl+delete=text:\\x15" # Delete line.
            ];
          };
      };
    };
}
