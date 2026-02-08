{ flake, ... }:
{
  imports = [
    flake.modules.nixos.programs-power-management
  ];
}
