{
  config,
  lib,
  pkgs,
  ...
}: let
  enable = config.modules.usrenv.compositor == "x11";
in
  lib.mkIf enable {
    # Windowing environment.
    services.xserver = {
      enable = true;
      xkb.layout = "us";
      xrandrHeads = ["Virtual-1"];
      autorun = true;

      desktopManager = {
        xterm.enable = false;
        wallpaper.mode = "fill";
      };

      displayManager = {
        gdm.enable = true;

        sessionCommands = ''
          ${lib.getExe pkgs.xorg.xset} r rate 200 40
        '';
      };

      windowManager.i3 = {inherit enable;};
    };

    services.displayManager.defaultSession = "none+i3";

    # List additional packages to install in system profile. To search, run:
    # $ nix search wget
    environment.systemPackages = with pkgs; [
      xclip
    ];
  }
