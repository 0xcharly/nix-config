{
  lib,
  usrlib,
  ...
} @ args: let
  inherit ((usrlib.config.getUserConfig args).modules.stdenv) isNixOS;
in {
  xdg.configFile = lib.optionalAttrs isNixOS {
    "cachix/cachix.dhall".source =
      args.config.lib.file.mkOutOfStoreSymlink args.osConfig.age.secrets."services/cachix.dhall".path;
  };
}
