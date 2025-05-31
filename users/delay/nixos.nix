{
  config,
  lib,
  usrlib,
  ...
} @ args: let
  inherit ((usrlib.hm.getUserConfig args).modules.system.security) isBasicAccessTier;
in
  lib.mkIf (config.isNixOS && isBasicAccessTier) {
    xdg.configFile."cachix/cachix.dhall".source =
      args.config.lib.file.mkOutOfStoreSymlink args.osConfig.age.secrets."services/cachix.dhall".path;
  }
