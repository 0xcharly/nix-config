{
  config,
  lib,
  pkgs,
  usrlib,
  ...
} @ args: let
  inherit ((usrlib.hm.getUserConfig args).modules) flags;
  home = config.home.homeDirectory;
in {
  programs.ssh = let
    mkIdentityFile = key: {IdentityFile = "${home}/.ssh/${key}";};
  in {
    enable = true;
    matchBlocks =
      {
        # Public services.
        "bitbucket.org" = {
          user = "git";
          extraOptions = mkIdentityFile "bitbucket";
        };
        "github.com" = {
          user = "git";
          extraOptions = mkIdentityFile "github";
        };
      }
      // lib.optionalAttrs flags.ssh.declareTailscaleEntryNodeHosts {
        # Tailscale nodes accessible from the public internet.
        linode = {
          hostname = "2600:3c18::2000:a4ff:fe80:d6d4";
          extraOptions = mkIdentityFile "tailscale-public";
        };
        # TODO: decommission this node.
        linode-arch = {
          hostname = "2400:8902::f03c:92ff:fea6:366e";
          extraOptions = mkIdentityFile "linode";
        };
      }
      // lib.optionalAttrs flags.ssh.declareTailscaleNetworkHosts (let
        # Tailscale nodes. Add all NixOS nodes to this list.
        tailscaleNodesMatchGroup = builtins.concatStringsSep " " (
          (lib.singleton "*.${flags.tailscale.tailnetName}") ++ flags.tailscale.allNodes
        );
        tailscaleNodesHostName = lib.attrsets.mergeAttrsList (
          builtins.map (host: {
            "${host}" = {hostname = "${host}.${flags.tailscale.tailnetName}";};
          })
          flags.tailscale.allNodes
        );
      in
        tailscaleNodesHostName
        // {
          "${tailscaleNodesMatchGroup}" = {
            extraOptions = mkIdentityFile "tailscale";
          };
          skullkid = {
            hostname = "192.168.86.43";
            extraOptions = mkIdentityFile "skullkid";
          };
        });
    userKnownHostsFile = "${home}/.ssh/known_hosts ${home}/.ssh/known_hosts.trusted";
  };

  home.file =
    {
      # Install known SSH keys for trusted hosts.
      ".ssh/known_hosts.trusted".text = let
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
    # Authorize backups of beans file.
    // lib.optionalAttrs flags.ssh.authorizeBeansBackupCommand {
      ".ssh/authorized_keys".text = ''
        command="${lib.getExe pkgs.rrsync} -ro ${home}/beans",restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGa3cDgdhUeqAP2Bmnew2/SfC6HiXslIUpyHQ8HsUUZO beans-backup
      '';
    }
    # TODO: add trusted tier version of these.
    // lib.optionalAttrs flags.ssh.installBasicAccessKeys (let
      mkSshKeySymLink = key: {
        ".ssh/${key}".source = args.config.lib.file.mkOutOfStoreSymlink args.osConfig.age.secrets."keys/basic-access/${key}_ed25519_key".path;
      };
    in
      lib.mergeAttrsList (builtins.map mkSshKeySymLink flags.ssh.basicAccessKeys));
}
