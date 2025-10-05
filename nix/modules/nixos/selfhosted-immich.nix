{flake, ...}: {
  config,
  lib,
  ...
}: {
  options.node.services.immich = with lib; {
    enable = mkEnableOption "Spin up an Immich service";
  };

  config.services = let
    cfg = config.node.services.immich;
    inherit (flake.lib) caddy facts gatus;
  in {
    immich = {
      inherit (cfg) enable;
      host = "0.0.0.0";
      inherit (facts.services.immich) port;
      mediaLocation = "/tank/delay/album";
      settings.server.externalDomain = "https://${facts.services.immich-public-proxy.domain}";
    };

    caddy.virtualHosts = caddy.mkReverseProxyConfig facts.services.immich;
    gatus.settings.endpoints = [
      (gatus.mkHttpServiceCheck "immich" facts.services.immich)
    ];
  };
}
