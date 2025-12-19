{flake, ...}: {
  config,
  lib,
  pkgs,
  ...
}: {
  options.node.services.reverse-proxy = with lib; {
    enable = mkEnableOption "Spin up a reverse proxy service via Caddy";
    "qyrnl.com" = {
      enable = mkEnableOption "Set up reverse proxy service for qyrnl.com";
      openFirewall = lib.mkEnableOption "Open firewall ports for qyrnl.com's reverse proxy";
      bindIP = lib.mkOption {
        type = lib.types.str;
        example = "10.0.0.1";
        description = "The network IP to bind domains to.";
      };
      bindInterface = lib.mkOption {
        type = lib.types.str;
        example = "eth0";
        default = config.services.tailscale.interfaceName;
        description = "The network interface to bind to.";
      };
    };
  };

  config = let
    cfg = config.node.services.reverse-proxy;
    inherit (flake.lib) caddy facts;
    inherit (facts.reverse-proxy."qyrnl.com") tmpl;
  in {
    services = {
      caddy = {
        inherit (cfg) enable;
        package = pkgs.caddy.withPlugins {
          plugins = ["github.com/caddy-dns/gandi@v1.1.0"];
          hash = "sha256-5mjD0CY7f5+sRtV1rXysj8PvId2gQaWiXlIaTg2Lv8A=";
        };
        environmentFile = config.age.secrets."services/gandi-creds.qyrnl.com".path;
        virtualHosts =
          {
            "(${tmpl})".extraConfig = ''
              bind ${cfg."qyrnl.com".bindIP}
              tls {
                resolvers 1.1.1.1
                dns gandi {env.GANDIV5_PERSONAL_ACCESS_TOKEN}
              }
            '';
          }
          // (let
            services = with facts.services; [
              atuin
              calibre-web
              cgit
              forgejo
              gatus
              gotify
              grafana
              immich-public-proxy
              immich
              jellyfin
              linkwarden
              miniflux
              navidrome
              paperless
              prometheus
              search
              vaultwarden
            ];
            reverse-proxy-configs = builtins.map caddy.mkReverseProxyConfig (
              builtins.map (service: service // {import = tmpl;}) services
            );
          in
            lib.mergeAttrsList reverse-proxy-configs);
      };
    };

    systemd.services.caddy = lib.mkIf cfg.enable {
      after = [
        "tailscaled.service"
        "tailscaled-autoconnect.service"
      ];
      unitConfig.Requires = ["tailscaled.service"];
      serviceConfig = {
        RestartSec = "5s";
        AmbientCapabilities = ["CAP_NET_BIND_SERVICE"]; # Allow Caddy to bind to 443.
      };
    };

    networking.firewall = lib.mkIf (cfg.enable && cfg."qyrnl.com".openFirewall) {
      interfaces.${cfg.reverse-proxy.bindInterface}.allowedTCPPorts = [80 443];
    };
  };
}
