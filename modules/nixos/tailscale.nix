{
  config,
  lib,
  ...
}:
lib.mkIf config.modules.system.roles.nixos.tailscaleNode {
  services.tailscale.enable = true;
}
