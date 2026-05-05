{ flake, ... }:
{
  imports = [
    flake.nixosModules.programs-power-management
  ];
}
