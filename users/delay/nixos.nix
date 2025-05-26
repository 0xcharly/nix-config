{
  config,
  lib,
  pkgs,
  ...
} @ args: let
  isNixOS = pkgs.stdenv.isLinux && config ? system.build;
in
  lib.mkIf isNixOS {
    xdg.configFile."cachix/cachix.dhall".source =
      args.config.lib.file.mkOutOfStoreSymlink args.osConfig.age.secrets."services/cachix.dhall".path;
  }
