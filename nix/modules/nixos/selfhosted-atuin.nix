# Atuin data is stored in postgresql database.
{flake, ...}: {
  config,
  lib,
  ...
}: {
  options.node.services.atuin = with lib; {
    enable = mkEnableOption "Spin up a Atuin service";
  };

  config = let
    cfg = config.node.services.atuin;
    inherit (flake.lib) caddy facts gatus;
  in {
    services = {
      atuin = {
        inherit (cfg) enable;
        inherit (facts.services.atuin) port;
        host = "0.0.0.0";
        openRegistration = false; # NOTE: temporary change this value to add new users.
      };

      caddy.virtualHosts = caddy.mkReverseProxyConfig facts.services.atuin;
      gatus.settings.endpoints = [
        (gatus.mkHttpServiceCheck "atuin" facts.services.atuin)
      ];
    };
  };
}
