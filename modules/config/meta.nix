{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib.types) str;
in {
  options.meta = {
    hostname = mkOption {
      type = str;
      default = config.networking.hostName;
      readOnly = true;
      description = ''
        The canonical hostname of the machine.

        Is usually used to identify, i.e., name machines internally
        or on the same Tailscale network. This option must be declared
        in {file}`hosts.nix` alongside host system.
      '';
    };

    system = mkOption {
      type = str;
      default = pkgs.stdenv.system;
      readOnly = true;
      description = ''
        The architecture of the machine.

        By default, this is is an alias for {option}`pkgs.stdenv.system` and
        {option}`nixpkgs.hostPlatform` in a top-level configuration.
      '';
    };
  };
}
