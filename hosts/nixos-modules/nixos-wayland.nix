{
  config,
  lib,
  pkgs,
  ...
}: let
  enable = config.usrenv.compositor == "wayland";
in {
  programs.sway = {inherit enable;};
  xdg.portal = lib.mkIf enable {
    inherit enable;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
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
      defaultSession = "sway";
    };

    libinput = {inherit enable;};
  };
}
