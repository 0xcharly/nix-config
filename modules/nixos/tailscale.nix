{
  config,
  lib,
  ...
}:
lib.mkIf config.modules.system.roles.nixos.tailscaleNode {
  services.tailscale = {
    enable = true;
    authKeyFile = config.age.secrets."services/tailscale-preauth.key".path;
  };

  # Enable Wezterm multiplexing on all Tailscale nodes.
  services.openssh = {
    enable = true;
    settings.AcceptEnv = "TERM_PROGRAM";
  };
}
