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
  in {
    services = {
      caddy = {
        inherit (cfg) enable;
        package = pkgs.caddy.withPlugins {
          plugins = ["github.com/caddy-dns/gandi@v1.1.0"];
          hash = "sha256-VxJlx1X4nrqprgcPRFt/pMc5Ix8YV61ou8dwLcR6v2U=";
        };
        environmentFile = config.age.secrets."services/gandi-creds.qyrnl.com".path;
        virtualHosts =
          {
            "(tailscale_reverse_proxy)".extraConfig = ''
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
              miniflux
              paperless
              prometheus
              vaultwarden
            ];
            reverse-proxy-configs = builtins.map caddy.mkReverseProxyConfig services;
          in
            lib.mergeAttrsList reverse-proxy-configs);
      };

      # caddy = lib.mkIf cfg.reverse-proxy.enable {
      #   inherit (cfg.reverse-proxy) enable;
      #   virtualHosts = lib.mergeAttrsList [
      #     (caddy.mkReverseProxyConfig (facts.services.pieceofenglish
      #       // {
      #         host = config.services.pieceofenglish.listenAddress;
      #         import = "";
      #       }))
      #     (caddy.mkWwwRedirectConfig facts.services.pieceofenglish)
      #   ];
      # };
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

        # TODO: do we need this?
        # } // lib.optionalsAttrs cfg."qyrnl.com".enable {
        # EnvironmentFile = config.age.secrets."services/gandi-creds.qyrnl.com".path;
      };
    };

    networking.firewall = lib.mkIf (cfg.enable && cfg."qyrnl.com".openFirewall) {
      interfaces.${cfg.reverse-proxy.bindInterface}.allowedTCPPorts = [80 443];
    };
  };
}
