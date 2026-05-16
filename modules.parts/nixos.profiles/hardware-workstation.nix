{ self, ... }:
{
  flake.nixosModules.profile-hardware-workstation = {
    imports = with self.nixosModules; [ programs-power-management ];
  };
}
