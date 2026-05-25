{ self, ... }:
{
  flake.homeModules.profile-hardware-wireless = {
    imports = with self.homeModules; [
      services-bluetooth
    ];
  };
}
