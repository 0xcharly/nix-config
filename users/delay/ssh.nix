{
  lib,
  pkgs,
  ...
} @ args: let
  config =
    if args ? osConfig
    then args.osConfig
    else args.config;
  inherit (pkgs.stdenv) isDarwin isLinux;
  inherit (config.modules.usrenv) isCorpManaged isHeadless;
in {
  programs.ssh = let
    # NOTE: most SSH servers use the default limit of 6 keys for authentication.
    # Once the server limit is reached, authentication will fail with "too many
    # authentication failures". reached, authentication will fail with "
    _1passwordAgentPathMacOS = "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    _1passwordAgentOrKey = key:
      lib.optionalAttrs isDarwin {IdentityAgent = "\"${_1passwordAgentPathMacOS}\"";}
      // lib.optionalAttrs (isLinux && !isHeadless) {IdentityFile = "~/.ssh/${key}";};
  in {
    enable = true;
    matchBlocks =
      {
        # Personal hosts.
        "bitbucket.org" = {
          user = "git";
          extraOptions = _1passwordAgentOrKey "bitbucket";
        };
        "github.com" = {
          user = "git";
          extraOptions = _1passwordAgentOrKey "github";
        };
        "linode" = {
          hostname = "172.105.192.143";
          extraOptions = _1passwordAgentOrKey "linode";
          forwardAgent = true;
        };
      }
      // (lib.optionalAttrs (isDarwin && !isCorpManaged) {
        # Home storage host.
        "skullkid.local" = {
          hostname = "192.168.86.43";
          extraOptions = _1passwordAgentOrKey "skullkid";
          forwardAgent = true;
        };
        # VMWare hosts.
        "192.168.*" = {
          extraOptions = _1passwordAgentOrKey "vm";
        };
      });
    userKnownHostsFile = "~/.ssh/known_hosts ~/.ssh/known_hosts.trusted";
  };

  # Install known SSH keys for trusted hosts.
  home.file.".ssh/known_hosts.trusted".text = ''
    192.168.86.43 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICT2Px+IB0pL69ctFv1SesgFD3gfTHw9SibG5FpITj9u
    172.105.192.143 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE/xP/0LQP88FKB3cQKuMvHCj53UiAMnV3rZFQiMsLkV
    bitbucket.org ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIazEu89wgQZ4bqs3d63QSMzYVa0MuJ2e2gKTKqu+UUO
    github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
  '';
}
