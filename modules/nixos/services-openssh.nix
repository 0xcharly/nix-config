{ self, ... }:
{
  flake.nixosModules.services-openssh =
    { lib, ... }:
    {
      # Install known SSH keys for trusted hosts
      programs.ssh.knownHosts = self.lib.openssh.knownHosts;

      # Enable the OpenSSH daemon
      services.openssh = {
        enable = true;

        settings = {
          PasswordAuthentication = lib.mkDefault true;
          PermitRootLogin = "no";
        };

        # Removes RSA. mkDefault: fs-btrfs-impermanence overrides this at
        # normal priority to relocate the key onto /persist; non-impermanent
        # hosts keep the /etc/ssh path.
        hostKeys = lib.mkDefault [
          {
            path = "/etc/ssh/ssh_host_ed25519_key";
            type = "ed25519";
          }
        ];
      };
    };
}
