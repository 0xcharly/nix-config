{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv) isLinux;
  inherit (config.settings) compositor isHeadless;

  enable = isLinux && !isHeadless && compositor == "x11";
in {
  xresources = lib.mkIf enable {
    extraConfig = builtins.readFile ./Xresources;
  };

  xsession = {
    inherit enable;
    windowManager = rec {
      i3 = {
        inherit enable;
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
              command = i3.config.terminal;
              notification = false;
            }
          ];
          keybindings = {
            "${i3.config.modifier}+Return" = "exec ${i3.config.terminal}";
            "${i3.config.modifier}+o" = "exec ${lib.getExe pkgs.rofi} -show run";
            "${i3.config.modifier}+1" = "workspace 1";
            "${i3.config.modifier}+2" = "workspace 2";
            "${i3.config.modifier}+3" = "workspace 3";
            "${i3.config.modifier}+4" = "workspace 4";
            "${i3.config.modifier}+5" = "workspace 5";
            "${i3.config.modifier}+Left" = "focus left";
            "${i3.config.modifier}+Right" = "focus right";
            "${i3.config.modifier}+Up" = "focus up";
            "${i3.config.modifier}+Down" = "focus down";
            "${i3.config.modifier}+Shift+Left" = "move left";
            "${i3.config.modifier}+Shift+Right" = "move right";
            "${i3.config.modifier}+Shift+Up" = "move up";
            "${i3.config.modifier}+Shift+Down" = "move down";
            "${i3.config.modifier}+Shift+1" = "move container to workspace 1";
            "${i3.config.modifier}+Shift+2" = "move container to workspace 2";
            "${i3.config.modifier}+Shift+3" = "move container to workspace 3";
            "${i3.config.modifier}+Shift+4" = "move container to workspace 4";
            "${i3.config.modifier}+Shift+5" = "move container to workspace 5";
            "${i3.config.modifier}+Shift+c" = "reload";
            "${i3.config.modifier}+Shift+r" = "restart";
          };
          inherit fonts;
          bars = [{inherit fonts;}];
        };
      };
    };
  };

  # Make cursor not tiny on HiDPI screens.
  home.pointerCursor = lib.mkIf enable {
    name = "Vanilla-DMZ";
    package = pkgs.vanilla-dmz;
    size = 128;
    x11.enable = true;
  };
}