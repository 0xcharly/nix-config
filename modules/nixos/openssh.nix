{lib, ...}: {
  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = lib.mkDefault true;
      PermitRootLogin = "no";
    };
  };

  users.users.delay.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIi4b0qJVhTYPykLFKx89tighmRFmYKV4AkkEqkBeAiG delay"
  ];
}
