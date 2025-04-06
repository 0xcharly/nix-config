{
  config,
  lib,
  ...
}:
lib.mkIf config.modules.system.roles.nixos.amdCpu {
  boot.kernelModules = ["kvm-amd"];
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
