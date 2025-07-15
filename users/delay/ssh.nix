{
  config,
  lib,
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
        # TODO: Convert to NixOS and join the tailnet.
        skullkid = {
          hostname = "192.168.86.43";
          extraOptions = mkIdentityFile "skullkid";
        };
      };
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
    // lib.optionalAttrs flags.ssh.installBasicAccessKeys (let
      mkOutOfStoreSymlink = fname: args.config.lib.file.mkOutOfStoreSymlink args.osConfig.age.secrets."keys/basic-access/${fname}".path;
      mkSshKeySymLink = key: {
        ".ssh/${key}".source = mkOutOfStoreSymlink "${key}_ed25519_key";
        ".ssh/${key}.pub".source = mkOutOfStoreSymlink "${key}_ed25519_key.pub";
      };
    in
      lib.mergeAttrsList (builtins.map mkSshKeySymLink flags.ssh.basicAccessKeys))
    // lib.optionalAttrs flags.ssh.installTrustedAccessKeys (let
      mkOutOfStoreSymlink = fname: args.config.lib.file.mkOutOfStoreSymlink args.osConfig.age.secrets."keys/trusted-access/${fname}".path;
      mkSshKeySymLink = key: {
        ".ssh/${key}".source = mkOutOfStoreSymlink "${key}_ed25519_key";
        ".ssh/${key}.pub".source = mkOutOfStoreSymlink "${key}_ed25519_key.pub";
      };
    in
      lib.mergeAttrsList (builtins.map mkSshKeySymLink flags.ssh.trustedAccessKeys));
}
