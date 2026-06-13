{ self, ... }:
{
  flake.nixosModules.profile-hardware-workstation = {
    imports = with self.nixosModules; [
      environment-man-pages
      programs-power-management
    ];
  };
}
