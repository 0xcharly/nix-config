{
  config,
  lib,
  pkgs,
  ...
}: let
  enable = config.settings.compositor == "x11";
in {
  # Windowing environment.
  services.xserver = {
    inherit enable;
    xkb.layout = "us";
    xrandrHeads = ["Virtual-1"];
    autorun = true;

    desktopManager = {
      xterm.enable = false;
      wallpaper.mode = "fill";
    };

    displayManager = {
      gdm = {inherit enable;};

      sessionCommands = ''
        ${lib.getExe pkgs.xorg.xset} r rate 200 40
      '';
    };

    windowManager.i3 = {inherit enable;};
  };

  services.displayManager = {
    inherit enable;
    defaultSession = "none+i3";
  };

  # List additional packages to install in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    xclip
  ];
}
