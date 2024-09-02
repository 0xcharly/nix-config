let
  users = {
    delay = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB/bLz52u0dTFYTfJelVbXbU+VK7H4OXgre/8Mgx1+cq";
  };

  machines = {
    linode = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE/xP/0LQP88FKB3cQKuMvHCj53UiAMnV3rZFQiMsLkV";
    mbp = "";
    skullkid = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICT2Px+IB0pL69ctFv1SesgFD3gfTHw9SibG5FpITj9u";
    studio = "";
  };
in {
  # Augment the list passed as parameter with the user `delay`'s public key.
  # This key is always trusted and should always be available to decypher Age
  # secrets.
  mkTrustedPublicKeys = keys: keys ++ [users.delay];

  # Collections of hosts by role.
  workstations = with machines; [mbp studio];
  servers = with machines; [linode skullkid];
}
