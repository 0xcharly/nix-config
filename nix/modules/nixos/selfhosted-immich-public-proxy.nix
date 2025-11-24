{flake, ...}: {
  config,
  lib,
  ...
}: {
  options.node.services.immich-public-proxy = with lib; {
    enable = mkEnableOption "Spin up an Immich Public Proxy service";
  };

  config.services = let
    cfg = config.node.services.immich-public-proxy;
    inherit (flake.lib) caddy facts;
  in {
    immich-public-proxy = {
      inherit (cfg) enable;
      inherit (facts.services.immich-public-proxy) port;
      immichUrl = "https://${facts.services.immich.domain}";
    };

    caddy.virtualHosts = caddy.mkReverseProxyConfig facts.services.immich-public-proxy;
  };
}
