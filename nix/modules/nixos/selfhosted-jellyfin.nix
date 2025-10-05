{flake, ...}: {
  config,
  lib,
  ...
}: {
  options.node.services.jellyfin = with lib; {
    enable = mkEnableOption "Spin up a Jellyfin service";
  };

  config.services = let
    cfg = config.node.services.jellyfin;
    inherit (flake.lib) caddy facts gatus;
  in {
    jellyfin = {
      inherit (cfg) enable;
      inherit (facts.jellyfin) dataDir;
    };

    caddy.virtualHosts = caddy.mkReverseProxyConfig facts.services.jellyfin;
    gatus.settings.endpoints = [
      (gatus.mkHttpServiceCheck "jellyfin" facts.services.jellyfin)
    ];
  };
}
