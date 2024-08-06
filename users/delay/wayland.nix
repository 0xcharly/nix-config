{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv) isLinux;
  inherit (config.settings) isHeadless;
in {
  programs.rofi.package = pkgs.rofi-wayland;

  home.packages = with pkgs; [
    wdisplays
    wlr-randr
    wl-clipboard
  ];

  home.sessionVariables = {
    NIXOS_OZONE_WL = 1;

    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    SDL_VIDEODRIVER = "wayland";
    XDG_SESSION_TYPE = "wayland";
  };

  wayland.windowManager.sway = rec {
    enable = isLinux && !isHeadless;
    config = let
      fonts = {
        names = ["IosevkaTerm Nerd Font" "FontAwesome6Free"];
        style = "Regular";
        size = 10.0;
      };
    in {
      modifier = "Mod4";
      terminal = lib.getExe pkgs.alacritty;
      startup = [
        {
          command = config.terminal;
        }
      ];
      keybindings = {
        "${config.modifier}+Return" = "exec ${config.terminal}";
        "${config.modifier}+o" = "exec ${lib.getExe pkgs.rofi} -show run";
        "${config.modifier}+1" = "workspace 1";
        "${config.modifier}+2" = "workspace 2";
        "${config.modifier}+3" = "workspace 3";
        "${config.modifier}+4" = "workspace 4";
        "${config.modifier}+5" = "workspace 5";
        "${config.modifier}+Left" = "focus left";
        "${config.modifier}+Right" = "focus right";
        "${config.modifier}+Up" = "focus up";
        "${config.modifier}+Down" = "focus down";
        "${config.modifier}+Shift+Left" = "move left";
        "${config.modifier}+Shift+Right" = "move right";
        "${config.modifier}+Shift+Up" = "move up";
        "${config.modifier}+Shift+Down" = "move down";
        "${config.modifier}+Shift+1" = "move container to workspace 1";
        "${config.modifier}+Shift+2" = "move container to workspace 2";
        "${config.modifier}+Shift+3" = "move container to workspace 3";
        "${config.modifier}+Shift+4" = "move container to workspace 4";
        "${config.modifier}+Shift+5" = "move container to workspace 5";
        "${config.modifier}+Shift+c" = "reload";
        "${config.modifier}+Shift+r" = "restart";
      };
      inherit fonts;
      bars = [{inherit fonts;}];
    };
  };
}
