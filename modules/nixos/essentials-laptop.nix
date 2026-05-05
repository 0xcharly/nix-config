{ flake, ... }:
{
  imports = with flake.nixosModules; [
    hardware-power-management
    programs-power-management
  ];
}
