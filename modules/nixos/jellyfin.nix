{
  config,
  lib,
  ...
}: let
  cfg = config.node.services.jellyfin;
in {
  options.node.services.jellyfin.enable = lib.mkEnableOption "Whether to spin up a Jellyfin server.";

  config.services = {
    jellyfin = {
      inherit (cfg) enable;
    };

    # TODO: define Jellyfin's host and port somewhere else.
    caddy.virtualHosts."jellyfin.qyrnl.com".extraConfig = ''
      import ts_host
      reverse_proxy helios.qyrnl.com:8096
    '';

    gatus.settings.endpoints = [
      (lib.fn.mkHttpServiceEndpoint "jellyfin" "jellyfin.qyrnl.com")
    ];
  };
}
