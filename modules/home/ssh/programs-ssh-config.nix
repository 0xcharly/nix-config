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
            "codeberg.org" = {
              User = "git";
              IdentityFile = mkIdentityFile "0xcharly";
            };
            "github.com" = {
              User = "git";
              IdentityFile = mkIdentityFile "0xcharly";
            };
            # KDDI (home ISP) peering to Linode Paris / Orange is ~15x slower
            # than hopping through Linode Tokyo (measured 2026-07: 0.4 MB/s
            # direct vs 5-9 MB/s via jump-jp). Neutral-to-better from other
            # networks. jump-jp down? `ssh -o ProxyJump=none <host>`.
            "site-fr" = {
              ProxyJump = "jump-jp";
            };
            "gate-fr" = {
              ProxyJump = "jump-jp";
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
