{pkgs, ...}: {
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

  # Required for graphical interfaces (X or Wayland) to work.
  security.polkit.enable = true;

  services = {
    xserver.displayManager.gdm = {
      enable = true;
      wayland = true;
    };
    displayManager.defaultSession = "hyprland-uwsm";
    libinput.enable = true;
  };
}
