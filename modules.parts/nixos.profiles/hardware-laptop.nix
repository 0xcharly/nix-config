{ self, ... }:
{
  flake.nixosModules.profile-hardware-laptop = {
    imports = with self.nixosModules; [
      hardware-power-management
      programs-power-management
    ];
  };
}
