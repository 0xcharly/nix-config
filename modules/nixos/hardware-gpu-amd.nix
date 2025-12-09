{flake, ...}: {
  imports = [flake.modules.nixos.hardware-gpu-common];

  boot.initrd.kernelModules = ["amdgpu"];
}
