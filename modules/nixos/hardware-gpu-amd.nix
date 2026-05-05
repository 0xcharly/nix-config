{ flake, ... }:
{
  imports = [ flake.nixosModules.hardware-gpu-common ];

  boot.initrd.kernelModules = [ "amdgpu" ];
}
