{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib.types) bool;
in {
  options.modules.stdenv = {
    isGenericLinux = mkOption {
      default = pkgs.stdenv.isLinux && (config.targets.genericLinux.enable or false);
      type = bool;
      readOnly = true;
      description = ''
        Whether this host is a non-NixOS Linux system.
      '';
    };

    isNixOS = mkOption {
      default = pkgs.stdenv.isLinux && !(config.targets.genericLinux.enable or false);
      type = bool;
      readOnly = true;
      description = ''
        Whether this host is a NixOS Linux system.
      '';
    };
  };
}
