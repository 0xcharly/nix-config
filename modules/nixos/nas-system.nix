{
  config,
  lib,
  ...
}:
lib.mkIf config.modules.system.roles.nas.enable {
  # Configure nixpkgs.
  nixpkgs.config.allowUnfree = true;

  # Don't require password for sudo.
  security.sudo.wheelNeedsPassword = false;
}
