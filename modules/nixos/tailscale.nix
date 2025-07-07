{
  config,
  lib,
  usrlib,
  ...
}:
lib.mkIf (usrlib.bool.isTrue config.modules.system.networking.tailscaleNode) {
  # Create group Tailscale.
  users.groups.tailscale = {};

  services.tailscale = {
    enable = true;
    authKeyFile = config.age.secrets."services/tailscale-preauth.key".path;
  };
}
