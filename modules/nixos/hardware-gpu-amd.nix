{ self, ... }:
{
  flake.nixosModules.hardware-gpu-amd = {
    imports = with self.nixosModules; [ hardware-gpu-common ];
    boot.initrd.kernelModules = [ "amdgpu" ];
  };
}
