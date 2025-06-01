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
    lib.optionals config.modules.system.networking.tailscaleNode [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIi4b0qJVhTYPykLFKx89tighmRFmYKV4AkkEqkBeAiG"
    ]
    ++ lib.optionals config.modules.system.networking.tailscalePublicNode [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHjAzWFwcBBC1brhZPmtHs39UEQU0IRtlcS/BEwfmqFj"
    ];
}
