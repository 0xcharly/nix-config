{
  config,
  lib,
  ...
}: let
  cfg = config.node.services.atuin;
in {
  options.node.services.atuin.enable = lib.mkEnableOption "Whether to spin up an Atuin server.";

  config.services = {
    atuin = {
      inherit (cfg) enable;
      openRegistration = false; # NOTE: temporary change this value to add new users.
    };

    caddy.virtualHosts."atuin.qyrnl.com" = {
      extraConfig = ''
        import ts_host
        reverse_proxy localhost:${toString config.services.atuin.port}
      '';
    };
  };
}
