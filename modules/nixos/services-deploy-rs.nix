{
  users.users.deploy = {
    isNormalUser = true;
    description = "Deploy user for deploy-rs";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKrS09tGMguVqYwvhOmMyVcJ0sZvJYV47sudqtWozKOp deploy-rs"
    ];
  };

  # TODO: Should we disallow login to all but allowlisted users?
  # services.openssh.settings.AllowUsers = ["deploy"];
  nix.settings.trusted-users = [ "deploy" ];

  security.sudo.extraRules = [
    {
      users = [ "deploy" ];
      commands = [
        # Authenticated via SSH Agent authentication: https://linux.die.net/man/8/pam_ssh_agent_auth.
        { command = "/nix/store/*-activatable-nixos-system-*/activate-rs"; }
        { command = "/run/current-system/sw/bin/rm /tmp/deploy-rs-canary-*"; }
      ];
    }
  ];
}
