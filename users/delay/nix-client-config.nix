{config, pkgs, lib, ...}: let
  isNixOS = pkgs.stdenv.isLinux && !(config.targets.genericLinux.enable or false);
in {
  # Use a ! prefix to skip validation at build time (which fails since the file
  # is not store in the Nix store).
  nix.extraOptions = lib.mkIf (!isNixOS) ''
    !include ${config.xdg.configHome}/nix/access-tokens.conf
  '';
}
