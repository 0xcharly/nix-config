{ flake, ... }:
{
  imports = [
    flake.modules.nixos.hardware-power-management
  ];
}
