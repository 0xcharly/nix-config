# https://nixos.wiki/wiki/Laptop
{
  flake.nixosModules.hardware-power-management = {
    powerManagement = {
      enable = true;
      powertop.enable = true; # Auto-tune on start
    };
  };
}
