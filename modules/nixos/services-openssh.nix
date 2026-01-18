{ flake, ... }:
{ lib, ... }:
{
  # Install known SSH keys for trusted hosts.
  programs.ssh.knownHosts = flake.lib.openssh.knownHosts;

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;

    settings = {
      PasswordAuthentication = lib.mkDefault true;
      PermitRootLogin = "no";
    };

    # Removes RSA.
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };
}
