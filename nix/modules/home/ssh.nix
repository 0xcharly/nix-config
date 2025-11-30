{flake, ...}: {config, ...}: {
  programs.ssh = let
    home = config.home.homeDirectory;
    mkIdentityFile = key: "${home}/.ssh/${key}";
  in {
    enable = true;
    matchBlocks = {
      "bitbucket.org" = {
        user = "git";
        identityFile = mkIdentityFile "bitbucket";
      };
      "github.com" = {
        user = "git";
        identityFile = mkIdentityFile "github";
      };
    };
    userKnownHostsFile = "${home}/.ssh/known_hosts ${home}/.ssh/known_hosts.trusted";
  };

  # Install known SSH keys for trusted hosts.
  home.file.".ssh/known_hosts.trusted".text = flake.lib.openssh.knownHostsFile;
}
