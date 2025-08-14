{
  config,
  lib,
  ...
}: let
  cfg = config.node.hardware.cpu;
in {
  options.node.hardware.cpu.vendor = lib.mkOption {
    type = lib.types.enum ["amd" "intel" "unknown"];
    default = "unknown";
    description = "Whether the machine has an AMD or Intel CPU.";
  };

  config = {
    boot.kernelModules =
      lib.optionals (cfg.vendor == "amd") ["kvm-amd"]
      ++ lib.optionals (cfg.vendor == "intel") ["kvm-intel"];

    hardware.cpu.amd.updateMicrocode = lib.mkIf (cfg.vendor != "unknown") (
      lib.mkDefault config.hardware.enableRedistributableFirmware
    );
  };
}
