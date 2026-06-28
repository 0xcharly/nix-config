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
          settings =
            let
              inherit (self.lib.facts.services.forgejo) ssh;
            in
            {
              "git.qyrnl.com" = {
                HostKeyAlias = ssh.domain;
                HostName = ssh.hostname;
                IdentityFile = mkIdentityFile "0xcharly";
                Port = ssh.port;
                User = "git";
              };
              "git.0xcharly.com" = {
                HostName = ssh.hostname;
                IdentityFile = mkIdentityFile "0xcharly";
                Port = ssh.port;
                User = "git";
                ProxyJump = "bastion.0xcharly.com";
              };
              "bastion.0xcharly.com" = {
                User = "delay";
                IdentityFile = mkIdentityFile "0xcharly";
              };
            };
        };
    };
}
