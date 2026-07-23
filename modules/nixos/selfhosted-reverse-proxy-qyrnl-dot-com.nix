{ self, ... }:
{
  flake.nixosModules.selfhosted-reverse-proxy-qyrnl-dot-com =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.node.services.reverse-proxy = with lib; {
        enable = mkEnableOption "Spin up a reverse proxy service via Caddy";
        "qyrnl.com" = {
          enable = mkEnableOption "Set up reverse proxy service for qyrnl.com";
          openFirewall = mkEnableOption "Open firewall ports for qyrnl.com's reverse proxy";
          bindIP = mkOption {
            type = types.str;
            example = "10.0.0.1";
            description = "The network IP to bind domains to.";
          };
          bindInterface = mkOption {
            type = types.str;
            example = "eth0";
            default = config.services.tailscale.interfaceName;
            description = "The network interface to bind to.";
          };
        };
      };

      config =
        let
          cfg = config.node.services.reverse-proxy;
          inherit (self.lib) caddy facts;
          inherit (facts.reverse-proxy."qyrnl.com") tmpl;
        in
        {
          services = {
            caddy = {
              inherit (cfg) enable;
              package = pkgs.caddy.withPlugins {
                plugins = [ "github.com/caddy-dns/gandi@v1.1.0" ];
                hash = "sha256-gY3Fo9nH9iJsd1ziwXH/TWFXYz622JSL0LIeigSWnUE=";
              };
              environmentFile = config.age.secrets."services/gandi-creds.qyrnl.com".path;
              # HTTP/3 has never been reachable here: the firewall below only
              # opens TCP 80/443, and QUIC datagrams from tailnet clients
              # exceed the tailscale0 MTU (1280) and fail client-side with
              # EMSGSIZE. Advertising `Alt-Svc: h3` breaks HTTP/3-capable
              # clients that trust it — notably python-caldav >= 2.2.5
              # (niquests), used by Errands, whose authenticated retry after a
              # 401 switches to h3 and aborts. Restrict Caddy to TCP protocols
              # so Alt-Svc is not emitted.
              globalConfig = ''
                servers {
                  protocols h1 h2
                }
              '';
              virtualHosts = {
                "(${tmpl})".extraConfig = ''
                  bind ${cfg."qyrnl.com".bindIP}
                  tls {
                    # No Mullvad DNS (194.242.2.2) here: it refuses plain
                    # port-53 queries from outside the VPN. Resolvers are only
                    # used for zone detection: the local propagation check is
                    # disabled (propagation_timeout -1) because polling public
                    # recursives right after record creation negative-caches
                    # the answer (Gandi SOA minimum 300s) for longer than the
                    # check window, failing every first issuance. Let's
                    # Encrypt validates against Gandi's authoritative servers
                    # directly; the fixed delay covers the Gandi API ->
                    # authoritative propagation lag.
                    resolvers 1.1.1.1 8.8.8.8
                    propagation_delay 30s
                    propagation_timeout -1
                    dns gandi {env.GANDIV5_PERSONAL_ACCESS_TOKEN}
                  }
                '';
              }
              // (
                let
                  services = with facts.services; [
                    atuin
                    forgejo
                    gatus
                    ggit
                    gotify
                    grafana
                    immich-public-proxy
                    immich
                    jellyfin
                    lidarr
                    linkwarden
                    miniflux
                    navidrome
                    paperless
                    prometheus
                    prowlarr
                    qui
                    radarr
                    radicale
                    sonarr
                    vaultwarden
                  ];
                  reverse-proxy-configs = map caddy.mkReverseProxyConfig (
                    map (service: service // { import = tmpl; }) services
                  );
                in
                lib.mergeAttrsList reverse-proxy-configs
              );
            };
          };

          systemd.services.caddy = lib.mkIf cfg.enable {
            after = [
              "tailscaled.service"
              "tailscaled-autoconnect.service"
            ];
            unitConfig.Requires = [ "tailscaled.service" ];
            serviceConfig = {
              RestartSec = "5s";
              AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ]; # Allow Caddy to bind to 443.
            };
          };

          networking.firewall = lib.mkIf (cfg.enable && cfg."qyrnl.com".openFirewall) {
            interfaces.${cfg.reverse-proxy.bindInterface}.allowedTCPPorts = [
              80
              443
            ];
          };
        };
    };
}
