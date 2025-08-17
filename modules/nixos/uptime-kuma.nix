{
  config,
  lib,
  ...
}: let
  cfg = config.node.services.uptime-kuma;
in {
  options.node.services.uptime-kuma.enable = lib.mkEnableOption "Whether to spin up an Uptime Kuma server.";

  config.services = {
    uptime-kuma = {
      inherit (cfg) enable;
      settings.PORT = "3001";
    };

    caddy.virtualHosts."status.qyrnl.com" = {
      extraConfig = ''
        import ts_host
        reverse_proxy localhost:${config.services.uptime-kuma.settings.PORT}
      '';
    };
  };
}
