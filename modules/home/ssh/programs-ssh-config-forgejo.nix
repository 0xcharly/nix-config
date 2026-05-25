{ self, ... }:
{
  flake.homeModules.programs-ssh-config-forgejo =
    { config, ... }:
    {
      programs.ssh =
        let
          mkIdentityFile = key: "${config.home.homeDirectory}/.ssh/${key}";
        in
        {
          # That's a lot of shenanigan to setup locally, but that's by far the
          # easiest configuration for now.
          matchBlocks."git.qyrnl.com" =
            let
              inherit (self.lib.facts.services.forgejo) ssh;
            in
            {
              user = "git";
              identityFile = mkIdentityFile "github";
              inherit (ssh) hostname port;
              extraOptions.HostKeyAlias = ssh.domain;
            };
        };
    };
}
