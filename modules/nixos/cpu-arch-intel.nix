{
  config,
  lib,
  ...
}:
lib.mkIf config.modules.system.roles.nixos.intelCpu {
  boot.kernelModules = ["kvm-intel"];
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
