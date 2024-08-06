{
  pkgs,
  globalModules,
  sharedModules,
  ...
}: {
  imports = with sharedModules; [nixos-headless];

  programs.sway.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
    ];
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Windowing environment.
  services = {
    displayManager = {
      sddm = {
        enable = true;
        wayland.enable = true;
      };
      defaultSession = "sway";
    };

    libinput.enable = true;
  };

  # Manage fonts.
  fonts = {
    fontDir.enable = true;

    packages = import globalModules.fonts {inherit pkgs;};
  };

  # TODO: factorize this with nixos-x11.nix setup.
  environment.etc = {
    "xdg/gtk-2.0/gtkrc".text = ''
      gtk-application-prefer-dark-theme=1
      gtk-error-bell=0
    '';
    "xdg/gtk-3.0/settings.ini".text = ''
      [Settings]
      gtk-application-prefer-dark-theme=1
      gtk-error-bell=false
    '';
    "xdg/gtk-4.0/settings.ini".text = ''
      [Settings]
      gtk-application-prefer-dark-theme=1
      gtk-error-bell=false
    '';
  };
}
