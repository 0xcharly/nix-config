{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.modules.usrenv.isLinuxWaylandDesktop {
  # Windowing environment.
  services = {
    xserver.displayManager.gdm = {
      enable = true;
      wayland = true;
    };
    displayManager.defaultSession = "hyprland-uwsm";
    libinput.enable = true;
  };

  programs = {
    hyprland = {
      enable = true;
      withUWSM = true;
      package = pkgs.hyprland;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
    };
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
