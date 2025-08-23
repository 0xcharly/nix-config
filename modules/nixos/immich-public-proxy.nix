{
  config,
  lib,
  ...
}: let
  cfg = config.node.services.immich-public-proxy;
in {
  options.node.services.immich-public-proxy.enable = lib.mkEnableOption "Whether to spin up an Immich Public Proxy (IPP) server.";

  config.services = {
    immich-public-proxy = {
      inherit (cfg) enable;
      immichUrl = "https://album.qyrnl.com";
    };

    caddy.virtualHosts."shared.album.qyrnl.com".extraConfig = ''
      import ts_host
      reverse_proxy localhost:${toString config.services.immich-public-proxy.port}
    '';

    gatus.settings.endpoints = [
      (lib.fn.mkHttpServiceEndpoint "immich-public-proxy" "shared.album.qyrnl.com")
    ];
  };
}
