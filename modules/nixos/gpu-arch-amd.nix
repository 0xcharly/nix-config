{
  config,
  pkgs,
  lib,
  ...
}:
lib.mkIf config.modules.system.roles.nixos.amdGpu {
  boot.initrd.kernelModules = ["amdgpu"];

  services.xserver.videoDrivers = ["modesetting"];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      vaapiVdpau
      libvdpau-va-gl
      mangohud
      amdvlk
    ];
    extraPackages32 = with pkgs; [mangohud];
  };
}
