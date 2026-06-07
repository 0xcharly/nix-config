{ self, ... }:
{
  flake.homeModules.programs-ssh-config =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      programs.ssh =
        let
          mkIdentityFile = key: "${config.home.homeDirectory}/.ssh/${key}";
        in
        {
          enable = true;
          enableDefaultConfig = false;
          settings = {
            "bitbucket.org" = {
              User = "git";
              IdentityFile = mkIdentityFile "bitbucket";
            };
            "codeberg.org" = {
              User = "git";
              IdentityFile = mkIdentityFile "github";
            };
            "github.com" = {
              User = "git";
              IdentityFile = mkIdentityFile "github";
            };
            "*" = {
              UserKnownHostsFile = lib.concatStringsSep " " [
                "${config.home.homeDirectory}/.ssh/known_hosts"
                # Install known SSH keys for trusted hosts
                (pkgs.writeText "known_hosts.trusted" self.lib.openssh.knownHostsFile)
              ];

              # The following options used to be the default before 25.11 (when
              # `enableDefaultConfig` was introduced).
              ForwardAgent = false;
              AddKeysToAgent = "no";
              Compression = false;
              ServerAliveInterval = 0;
              ServerAliveCountMax = 3;
              HashKnownHosts = false;
              ControlMaster = "no";
              ControlPath = "${config.home.homeDirectory}/.ssh/master-%r@%n:%p";
              ControlPersist = "no";
            };
          };
        };
    };
}
