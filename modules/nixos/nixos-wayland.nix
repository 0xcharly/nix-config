{
  config,
  lib,
  pkgs,
  ...
}: let
  enable = config.modules.usrenv.compositor == "wayland";
in
  lib.mkIf enable {
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        qt5.qtwayland
        qt6.qtwayland
        xdg-desktop-portal-gtk
        xdg-desktop-portal-wlr
      ];
    };

    # Windowing environment.
    services = {
      xserver.displayManager.gdm = {
        enable = true;
        wayland = true;
      };
      displayManager.defaultSession = "hyprland-uwsm";

      libinput = {inherit enable;};
    };

    programs = {
      hyprland = {
        enable = true;
        withUWSM = true;
      };
      hyprlock.enable = true;
      uwsm = {
        enable = true;
        waylandCompositors.hyprland = {
          prettyName = "Hyprland";
          comment = "Hyprland compositor managed by UWSM";
          binPath = "/run/current-system/sw/bin/Hyprland";
        };
      };
    };
  }
