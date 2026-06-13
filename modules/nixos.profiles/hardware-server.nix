{ self, ... }:
{
  flake.nixosModules.profile-hardware-server = {
    imports = with self.nixosModules; [ environment-man-less ];
  };
}
