{ flake, ... }:
{
  imports = [
    flake.modules.nixos.hardware-power-management
    flake.modules.nixos.programs-power-management
  ];
}
