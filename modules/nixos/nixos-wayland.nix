{
  config,
  lib,
  pkgs,
  ...
}: let
  enable = config.modules.usrenv.compositor == "wayland";
in {
  xdg.portal = lib.mkIf enable {
    inherit enable;
    extraPortals = with pkgs; [
      qt5.qtwayland
      qt6.qtwayland
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
    ];
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Windowing environment.
  services = lib.mkIf enable {
    displayManager = {
      sddm = {
        inherit enable;
        wayland.enable = true;
      };
      defaultSession = "hyprland";
    };

    libinput = {inherit enable;};
  };
}
