let
  users = {
    delay = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDCEnfq7QnNiGdyimKkEgEYuwT1xx0God9raxJ3Rimty";
  };

  machines = {
    linode = ""; # TODO: udpate after deploying the VM.
    nyx = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJmofQEhKZ7TOhqDMBwBr/p7ffOq2caH43ea1w/AsKoS";
    skullkid = ""; # TODO: udpate after deploying the NAS.
  };
in {
  # Augment the list passed as parameter with the user `delay`'s public key.
  # This key is always trusted and should always be available to decypher Age
  # secrets.
  mkTrustedPublicKeys = keys: keys ++ [users.delay];

  # Collections of hosts by role.
  workstations = with machines; [nyx];
  servers = with machines; [linode skullkid];
}
