{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.asdcontrol;
in {
  options.programs.asdcontrol = {
    enable = lib.mkEnableOption "Enables asdcontrol (brightness control for Apple Monitors)";
  };

  config = lib.mkIf cfg.enable {
    environment.defaultPackages = [pkgs.asdcontrol];
    services.udev.extraRules = ''
      KERNEL=="hiddev*", ATTRS{idVendor}=="05ac", ATTRS{idProduct}=="1114", GROUP="users", OWNER="root", MODE="0660"
      KERNEL=="hiddev*", ATTRS{idVendor}=="05ac", ATTRS{idProduct}=="9243", GROUP="users", OWNER="root", MODE="0660"
    ''; # Studio Display (1114), Pro Display XDR (9243)
  };
}
