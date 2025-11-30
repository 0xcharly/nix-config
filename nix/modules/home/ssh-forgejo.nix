{flake, ...}: {config, ...}: {
  programs.ssh = let
    home = config.home.homeDirectory;
    mkIdentityFile = key: "${home}/.ssh/${key}";
  in {
    # That's a lot of shenanigan to setup locally, but that's by far the
    # easiest configuration for now.
    matchBlocks."git.qyrnl.com" = let
      inherit (flake.lib.facts.services.forgejo) ssh;
    in {
      user = "git";
      identityFile = mkIdentityFile "github";
      inherit (ssh) hostname port;
      extraOptions.HostKeyAlias = ssh.domain;
    };
  };
}
