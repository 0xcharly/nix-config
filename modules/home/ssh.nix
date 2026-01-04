{flake, ...}: {
  config,
  lib,
  pkgs,
  ...
}: {
  programs.ssh = let
    home = config.home.homeDirectory;
    mkIdentityFile = key: "${home}/.ssh/${key}";
  in {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "bitbucket.org" = {
        user = "git";
        identityFile = mkIdentityFile "bitbucket";
      };
      "codeberg.org" = {
        user = "git";
        identityFile = mkIdentityFile "github";
      };
      "github.com" = {
        user = "git";
        identityFile = mkIdentityFile "github";
      };
      "*" = {
        userKnownHostsFile = lib.concatStringsSep " " [
          "${home}/.ssh/known_hosts"
          # Install known SSH keys for trusted hosts.
          (pkgs.writeText "known_hosts.trusted" flake.lib.openssh.knownHostsFile)
        ];

        # The following options used to be the default before 25.11 (when
        # `enableDefaultConfig` was introduced).
        forwardAgent = false;
        addKeysToAgent = "no";
        compression = false;
        serverAliveInterval = 0;
        serverAliveCountMax = 3;
        hashKnownHosts = false;
        controlMaster = "no";
        controlPath = "${home}/.ssh/master-%r@%n:%p";
        controlPersist = "no";
      };
    };
  };
}
