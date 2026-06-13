{ self, ... }:
{
  flake.nixosModules.profile-hardware-workstation-laptop = {
    imports = with self.nixosModules; [
      hardware-power-management
    ];
  };
}
