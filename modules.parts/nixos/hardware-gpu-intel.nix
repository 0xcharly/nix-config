{ self, ... }:
{
  flake.nixosModules.hardware-gpu-intel = {
    imports = with self.nixosModules; [ hardware-gpu-common ];
  };
}
