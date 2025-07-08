{
  config,
  lib,
  ...
}: {
  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = lib.mkDefault true;
      PermitRootLogin = "no";
    };
  };

  users.users.delay.openssh.authorizedKeys.keys =
    # This key is not used on a daily basis (Tailscale SSH is preferred), but
    # exists as a fallback.
    lib.optionals config.modules.system.networking.tailscaleNode [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIi4b0qJVhTYPykLFKx89tighmRFmYKV4AkkEqkBeAiG tailscale-internal"
    ]
    # Tailscale nodes opened to the public internet accept a different key. The
    # above one should be limited to internal connections only, while this one
    # should be limited to external connections only (such that it can be
    # revoked without impacting internal connections).
    ++ lib.optionals config.modules.system.networking.tailscalePublicNode [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHjAzWFwcBBC1brhZPmtHs39UEQU0IRtlcS/BEwfmqFj tailscale-public"
    ];
}
