{ self, ... }:
{
  flake.nixosModules.selfhosted-reverse-proxy-qyrnl-dot-com =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      domainName = "qyrnl.com";
    in
    {
      # `node.services.reverse-proxy.enable` and the shared Caddy plumbing
      # live in selfhosted-reverse-proxy-preamble.nix.
      options.node.services.reverse-proxy.${domainName} = with lib; {
        enable = mkEnableOption "Set up reverse proxy service for ${domainName}";
        openFirewall = mkEnableOption "Open firewall ports for ${domainName}'s reverse proxy";
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

      config =
        let
          cfg = config.node.services.reverse-proxy.${domainName};
          inherit (self.lib) caddy facts;
          inherit (facts.reverse-proxy.${domainName}) tmpl;
        in
        {
          services.caddy = {
            package = pkgs.caddy.withPlugins {
              plugins = [ "github.com/caddy-dns/gandi@v1.1.0" ];
              hash = "sha256-gY3Fo9nH9iJsd1ziwXH/TWFXYz622JSL0LIeigSWnUE=";
            };
            environmentFile = config.age.secrets."services/gandi-creds.${domainName}".path;
            virtualHosts = {
              "(${tmpl})".extraConfig = ''
                bind ${cfg.bindIP}
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

          networking.firewall = lib.mkIf (cfg.enable && cfg.openFirewall) {
            interfaces.${cfg.bindInterface}.allowedTCPPorts = [
              80
              443
            ];
          };
        };
    };
}
