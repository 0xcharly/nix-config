{
  config,
  lib,
  ...
} @ args:
lib.mkIf config.isNixOS {
  xdg.configFile."cachix/cachix.dhall".source =
    args.config.lib.file.mkOutOfStoreSymlink args.osConfig.age.secrets."services/cachix.dhall".path;
}
