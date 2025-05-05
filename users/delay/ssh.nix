{
  lib,
  pkgs,
  usrlib,
  ...
} @ args: let
  config =
    if args ? osConfig
    then args.osConfig
    else args.config;
  inherit (pkgs.stdenv) isDarwin;
  inherit (config.modules.usrenv) isCorpManaged isHeadless sshAgent;
in {
  programs.ssh = let
    # NOTE: most SSH servers use the default limit of 6 keys for authentication.
    # Once the server limit is reached, authentication will fail with "too many
    # authentication failures".
    use1PasswordSshAgent = isDarwin && (sshAgent == "1password");
    _1passwordAgentPathMacOS = "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    _1passwordAgentOrKey = key:
      lib.optionalAttrs use1PasswordSshAgent {IdentityAgent = "\"${_1passwordAgentPathMacOS}\"";}
      // lib.optionalAttrs (!isHeadless) {IdentityFile = "~/.ssh/${key}";};
  in {
    enable = true;
    matchBlocks =
      {
        # Public services.
        "bitbucket.org" = {
          user = "git";
          extraOptions = _1passwordAgentOrKey "bitbucket";
        };
        "github.com" = {
          user = "git";
          extraOptions = _1passwordAgentOrKey "github";
        };
      }
      // (lib.optionalAttrs isCorpManaged {
        # Personal hosts open to corp devices.
        linode = {
          hostname = "172.105.192.143";
          extraOptions = _1passwordAgentOrKey "linode";
          forwardAgent = true;
        };
      })
      // (lib.optionalAttrs (!isCorpManaged) (let
        # Tailscale nodes. Add all NixOS nodes to this list.
        tailscaleNodes = ["linode" "nyx" "helios" "selene"];
        tailscaleNodesMatchGroup = builtins.concatStringsSep " " (
          (lib.singleton "*.neko-danio.ts.net") ++ tailscaleNodes
        );
        tailscaleNodesHostName = lib.attrsets.mergeAttrsList (
          builtins.map (host: {
            "${host}" = {hostname = "${host}.neko-danio.ts.net";};
          })
          tailscaleNodes
        );
      in
        tailscaleNodesHostName
        // {
          "${tailscaleNodesMatchGroup}" = {
            extraOptions = _1passwordAgentOrKey "tailscale";
            forwardAgent = true;
          };
          skullkid = {
            hostname = "192.168.86.43";
            extraOptions = _1passwordAgentOrKey "skullkid";
            forwardAgent = true;
          };
        }));
    userKnownHostsFile = "~/.ssh/known_hosts ~/.ssh/known_hosts.trusted";
  };

  # Install known SSH keys for trusted hosts.
  home.file.".ssh/known_hosts.trusted".text = let
    extraKnownHosts = {
      # TODO: update Skullkid once migrated to NixOS and Tailscale.
      "192.168.86.43" = {
        ecdsa-sha2-nistp256 = "AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHiIQCyO9THWqAxDtfS/QixESfaAC2kXOCjYHTR9oDhuWCX5gvR2zCqYGMfZiQOFrE+am2kqSIheZ0HABxTRZmQ=";
        ssh-ed25519 = "AAAAC3NzaC1lZDI1NTE5AAAAICT2Px+IB0pL69ctFv1SesgFD3gfTHw9SibG5FpITj9u";
        ssh-rsa = "AAAAB3NzaC1yc2EAAAADAQABAAABgQD0+m8i3AltBVajoem4XioRqXnTF7WsQMm7w4zlYxw0lCYIwyvhoMKO46E8f4MP6qCRHzvWKMpqsGOy5gKpva0/VtSYyvDXH8BhMr4sf/g30Dz8zY+CVPhLKYVbZD9ZasrD66CkqYSVLb0yqHD70D8NPEzqDW/hfJLF7NUMqhG9HkIMroo6weAHjHdIRyu4nvGOId1/wSNY0i1epxLkqkqMQt3Qp1oYGVAfQyKynJ0tRfarf1VJcn7b5XpV5g+xF7uhXIIdCuGC8vDW9SZ0RUar8qP2B1ooiH9IBtEFpWKRA6rXUsWrisQJFIRljjKYrBQm8zIfxIkscuXBlkoMfhFI7CLa38mk/ADnJIkHXfcre3Zg/TPYln1HLu08doUkjRZLWojRuxDQfjmUHtGfix7hAJbEVEx74vCBNIqsCPLdq1ToBXB2QUOSXn5Mx6zRJVcQzLXIYllRaywIxH4+fanMGVslV5hnos7DlhJyngH2wnUS3XsAhH7Hikl2zEGymXM=";
      };
    };
  in
    usrlib.ssh.genKnownHostsFile {inherit extraKnownHosts;};
}
