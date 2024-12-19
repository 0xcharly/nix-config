{
  lib,
  pkgs,
  ...
} @ args: let
  config =
    if args ? osConfig
    then args.osConfig
    else args.config;
  inherit (pkgs.stdenv) isLinux;
  inherit (config.modules.usrenv) compositor;

  enable = isLinux && compositor == "wayland";
in {
  programs.rofi = lib.mkIf enable {
    package = pkgs.rofi-wayland;
  };

  home.packages = lib.optionals enable (with pkgs; [
    wdisplays
    wlr-randr
    wl-clipboard
  ]);

  home.sessionVariables = lib.mkIf enable {
    NIXOS_OZONE_WL = 1;

    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    SDL_VIDEODRIVER = "wayland";
    XDG_SESSION_TYPE = "wayland";
  };

  wayland.windowManager = rec {
    sway = {
      inherit enable;
      config = let
        fonts = {
          names = ["Iosevka Term Curly" "FontAwesome6Free"];
          style = "Regular";
          size = 10.0;
        };
      in {
        modifier = "Mod4";
        terminal = lib.getExe pkgs.ghostty;
        startup = [
          {
            command = sway.config.terminal;
          }
        ];
        keybindings = {
          "${sway.config.modifier}+Return" = "exec ${sway.config.terminal}";
          "${sway.config.modifier}+o" = "exec ${lib.getExe pkgs.rofi} -show run";
          "${sway.config.modifier}+1" = "workspace 1";
          "${sway.config.modifier}+2" = "workspace 2";
          "${sway.config.modifier}+3" = "workspace 3";
          "${sway.config.modifier}+4" = "workspace 4";
          "${sway.config.modifier}+5" = "workspace 5";
          "${sway.config.modifier}+Left" = "focus left";
          "${sway.config.modifier}+Right" = "focus right";
          "${sway.config.modifier}+Up" = "focus up";
          "${sway.config.modifier}+Down" = "focus down";
          "${sway.config.modifier}+Shift+Left" = "move left";
          "${sway.config.modifier}+Shift+Right" = "move right";
          "${sway.config.modifier}+Shift+Up" = "move up";
          "${sway.config.modifier}+Shift+Down" = "move down";
          "${sway.config.modifier}+Shift+1" = "move container to workspace 1";
          "${sway.config.modifier}+Shift+2" = "move container to workspace 2";
          "${sway.config.modifier}+Shift+3" = "move container to workspace 3";
          "${sway.config.modifier}+Shift+4" = "move container to workspace 4";
          "${sway.config.modifier}+Shift+5" = "move container to workspace 5";
          "${sway.config.modifier}+Shift+c" = "reload";
          "${sway.config.modifier}+Shift+r" = "restart";
        };
        inherit fonts;
        bars = [{inherit fonts;}];
      };
      extraConfig = ''
        input "type:keyboard" {
          repeat_delay 200
          repeat_rate 60
        }
        output DP-3 {
          mode 3840x2160@239.991Hz
        }
      '';
    };
  };
}
