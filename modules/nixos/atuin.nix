{
  config,
  lib,
  ...
}: let
  cfg = config.node.services.atuin;
in {
  options.node.services.atuin.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      If true, host spins up an Atuin server.

      https://atuin.sh
    '';
  };

  config.services.atuin = {
    inherit (cfg) enable;
    openRegistration = false; # NOTE: temporary change this value to add new users.
  };
}
