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

  # Automatically launch UWSM on login.
  environment.loginShellInit = ''
    [[ "$(tty)" == "/dev/tty1" ]] && exec uwsm start default >/dev/null 2>&1
  '';

  # Required for graphical interfaces (X or Wayland) to work.
  security.polkit.enable = true;
}
