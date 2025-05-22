{
  config,
  lib,
  usrlib,
  ...
} @ args: let
  inherit ((usrlib.hm.getUserConfig args).modules.stdenv) isNixOS;
in
  lib.mkIf isNixOS {
    xdg.configFile."cachix/cachix.dhall".source =
      args.config.lib.file.mkOutOfStoreSymlink args.osConfig.age.secrets."services/cachix.dhall".path;

    # Use a ! prefix to skip validation at build time (which fails since the file
    # is not store in the Nix store).
    nix.extraOptions = ''
      !include ${config.xdg.configHome}/nix/access-tokens.conf
    '';
  }
