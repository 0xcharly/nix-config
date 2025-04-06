{
  config,
  lib,
  ...
}:
lib.mkIf config.modules.system.roles.nixos.amdGpu {
  hardware.graphics.enable = true;
}
