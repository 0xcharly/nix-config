{lib, ...} @ args: let
  config =
    if args ? osConfig
    then args.osConfig
    else args.config;

  inherit (config.modules.stdenv) isNixOS;
in {
  xdg.configFile = lib.optionalAttrs isNixOS {
    "cachix/cachix.dhall".source = args.config.lib.file.mkOutOfStoreSymlink args.osConfig.age.secrets."services/cachix.dhall".path;
  };
}
