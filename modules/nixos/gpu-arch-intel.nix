{
  config,
  lib,
  ...
}:
lib.mkIf config.modules.system.roles.nixos.intelGpu {
  hardware.graphics.enable = true;
}
