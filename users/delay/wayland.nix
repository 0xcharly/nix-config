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
  programs = lib.mkIf enable {
    rofi.package = pkgs.rofi-wayland;
    swaylock = {
      enable = true;
      catppuccin.enable = true;
    };
  };

  home.packages = lib.optionals enable (with pkgs; [
    grim # Screenshot functionality
    mako # Notification system developed by swaywm maintainer
    slurp # Screenshot functionality
    wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
    wlr-randr # Utility to manage outputs of a Wayland compositor
  ]);

  home.sessionVariables = lib.mkIf enable {
    NIXOS_OZONE_WL = 1;

    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
    XDG_SESSION_TYPE = "wayland";
  };

  wayland.windowManager = rec {
    sway = {
      inherit enable;
      catppuccin.enable = true;
      config = let
        fonts = {
          names = ["Iosevka Term Curly" "FontAwesome6Free"];
          style = "Regular";
          size = 10.0;
        };
      in {
        modifier = "Mod4";
        terminal = lib.getExe pkgs.ghostty;
        defaultWorkspace = "workspace 3";
        assigns = {
          "0" = [{class = "^Firefox$";}];
          "1" = [{class = "^Chromium$";}];
        };
        startup = [
          {command = lib.getExe args.config.programs.firefox.finalPackage;}
          {command = lib.getExe args.config.programs.chromium.package;}
          {command = sway.config.terminal;}
        ];
        # floating.criteria = [
        #   {
        #     app_id = "firefox";
        #     title = "^Picture-in-Picture$";
        #   }
        # ];
        window.commands = [
          {
            command = "floating enable, sticky enable";
            criteria = {
              app_id = "firefox";
              title = "^Picture-in-Picture$";
            };
          }
        ];
        keybindings = {
          "${sway.config.modifier}+Return" = "exec ${sway.config.terminal}";
          "${sway.config.modifier}+Space" = "exec ${lib.getExe pkgs.rofi} -show run";
          "Mod1+1" = "workspace 1";
          "Mod1+2" = "workspace 2";
          "Mod1+3" = "workspace 3";
          "Mod1+4" = "workspace 4";
          "Mod1+5" = "workspace 5";
          "Mod1+Shift+1" = "move container to workspace 1";
          "Mod1+Shift+2" = "move container to workspace 2";
          "Mod1+Shift+3" = "move container to workspace 3";
          "Mod1+Shift+4" = "move container to workspace 4";
          "Mod1+Shift+5" = "move container to workspace 5";
          "${sway.config.modifier}+Left" = "focus left";
          "${sway.config.modifier}+Right" = "focus right";
          "${sway.config.modifier}+Up" = "focus up";
          "${sway.config.modifier}+Down" = "focus down";
          "${sway.config.modifier}+Shift+Left" = "move left";
          "${sway.config.modifier}+Shift+Right" = "move right";
          "${sway.config.modifier}+Shift+Up" = "move up";
          "${sway.config.modifier}+Shift+Down" = "move down";
          "${sway.config.modifier}+Shift+c" = "reload";
          "${sway.config.modifier}+Shift+r" = "restart";
        };
        inherit fonts;
        bars = [{inherit fonts;}];
        input = {
          "type:keyboard" = {
            repeat_delay = "200";
            repeat_rate = "60";
          };
        };
        output = {
          "DP-3" = {
            mode = "3840x2160@239.991Hz";
            scale = "1.25";
          };
        };
      };
      extraSessionCommands = ''
        export XDG_SESSION_TYPE=wayland
        export XDG_CURRENT_DESKTOP=sway
        export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
        export QT_AUTO_SCREEN_SCALE_FACTOR=0
        export QT_SCALE_FACTOR=1.25
        export GDK_SCALE=1.25
        export GDK_DPI_SCALE=1.25
        export MOZ_ENABLE_WAYLAND=1
        export _JAVA_AWT_WM_NONREPARENTING=1
      '';
      wrapperFeatures = {
        base = true;
        gtk = true;
      };
      xwayland = true;
    };
  };

  # Make cursor not tiny on HiDPI screens.
  home.pointerCursor = lib.mkIf enable {
    name = "Vanilla-DMZ";
    package = pkgs.vanilla-dmz;
    size = 256;
    x11 = {
      enable = true;
      defaultCursor = "Vanilla-DMZ";
    };
  };
}
