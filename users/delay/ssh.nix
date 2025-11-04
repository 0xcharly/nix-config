{
  config,
  lib,
  usrlib,
  ...
} @ args: let
  inherit ((lib.user.getUserConfig args).modules) flags;
  home = config.home.homeDirectory;
in {
  programs.ssh = let
    mkIdentityFile = key: {IdentityFile = "${home}/.ssh/${key}";};
  in {
    enable = true;
    matchBlocks = {
      # Public services.
      "bitbucket.org" = {
        user = "git";
        extraOptions = mkIdentityFile "bitbucket";
      };
      "github.com" = {
        user = "git";
        extraOptions = mkIdentityFile "github";
      };
    };
    userKnownHostsFile = "${home}/.ssh/known_hosts ${home}/.ssh/known_hosts.trusted";
  };

  home.file =
    {
      # Install known SSH keys for trusted hosts.
      ".ssh/known_hosts.trusted".text = usrlib.ssh.mkKnownHostsFile {};
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
