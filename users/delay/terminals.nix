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
        } {
          font-family = "mononoki";
          font-size = 16;
          theme = "catppuccin-mocha";
          minimum-contrast = 1.1;
          cursor-style = "block";
          cursor-style-blink = false;
          mouse-hide-while-typing = true;
          background-opacity = 0.95;
          unfocused-split-opacity = 1.0;
          background-blur-radius = 20;
          window-padding-balance = true;
          title = "‎";
          keybind = "super+shift+comma=reload_config";
          shell-integration-features = "no-cursor,no-sudo,no-title";
          confirm-close-surface = false;
          quit-after-last-window-closed = true;
        };
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
