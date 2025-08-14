{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.node.hardware.gpu;
in {
  options.node.hardware.gpu.vendor = lib.mkOption {
    type = lib.types.enum ["amd" "intel" "nvidia" "unknown"];
    default = "unknown";
    description = "Whether the machine has an AMD, Intel or Nvidia GPU.";
  };

  config = {
    boot.initrd.kernelModules = lib.optionals (cfg.vendor == "amd") ["amdgpu"];

    hardware.graphics = lib.mkIf (cfg.vendor != "unknown") {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        libvdpau-va-gl
        mangohud
        vaapiVdpau
      ];
      extraPackages32 = with pkgs; [mangohud];
    };
  };
}
