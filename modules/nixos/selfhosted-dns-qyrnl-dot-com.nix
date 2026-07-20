{ self, ... }:
{
  flake.nixosModules.selfhosted-dns-qyrnl-dot-com =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      domainName = "qyrnl.com";
      tailnetDomainName = "neko-danio.ts.net";
    in
    {
      options.node.services.dns.${domainName} = with lib; {
        enable = mkEnableOption "Spin up a DNS server for the ${domainName} domain";

        bindInterface = mkOption {
          type = types.str;
          example = "eth0";
          default = config.services.tailscale.interfaceName;
          description = "The network interface to bind to.";
        };

        blocking = {
          enable = mkEnableOption "Filter ads/tracking domains through a local Blocky instance";

          listenAddress = mkOption {
            type = types.str;
            default = "127.0.0.1:5301";
            description = "Loopback ip:port Blocky serves DNS on; CoreDNS forwards non-authoritative queries here.";
          };
        };
      };

      config =
        let
          cfg = config.node.services.dns.${domainName};
          inherit (self.lib) facts;
        in
        {
          services.coredns = {
            inherit (cfg) enable;

            config =
              let
                records = facts.dns.${domainName};
                reverseProxyHostName = facts.reverse-proxy.${domainName}.host;
                zoneFile = pkgs.writeText domainName ''
                  $ORIGIN ${domainName}.
                  $TTL    3600

                  @             IN SOA   ns.${domainName}. hostmaster.${domainName}. 2025070100 86400 10800 3600000 3600
                  @       300   IN NS    ns1.${domainName}.
                  @       300   IN NS    ns2.${domainName}.
                  ns1     300   IN A     ${records.ns1.ipv4}
                  ns1     300   IN AAAA  ${records.ns1.ipv6}
                  ns2     300   IN A     ${records.ns2.ipv4}
                  ns2     300   IN AAAA  ${records.ns2.ipv6}

                  ; Hosts declaration.
                  gate-fr       IN CNAME gate-fr.${tailnetDomainName}.
                  gate-jp       IN CNAME gate-jp.${tailnetDomainName}.
                  jump-jp       IN CNAME jump-jp.${tailnetDomainName}.
                  node-skl      IN CNAME node-skl.${tailnetDomainName}.
                  site-fr       IN CNAME site-fr.${tailnetDomainName}.
                  site-jp       IN CNAME site-jp.${tailnetDomainName}.
                  nyx           IN CNAME nyx.${tailnetDomainName}.
                  term-nyx      IN CNAME nyx.${tailnetDomainName}.
                  fwk           IN CNAME fwk.${tailnetDomainName}.
                  term-fwk      IN CNAME fwk.${tailnetDomainName}.
                  term-x1p      IN CNAME term-x1p.${tailnetDomainName}.

                  ; Services declaration.
                  album         IN CNAME ${reverseProxyHostName}
                  atuin         IN CNAME ${reverseProxyHostName}
                  cal           IN CNAME ${reverseProxyHostName}
                  contacts      IN CNAME ${reverseProxyHostName}
                  files         IN CNAME ${reverseProxyHostName}
                  git           IN CNAME ${reverseProxyHostName}
                  github        IN CNAME ${reverseProxyHostName}
                  graphs        IN CNAME ${reverseProxyHostName}
                  jellyfin      IN CNAME ${reverseProxyHostName}
                  lidarr        IN CNAME ${reverseProxyHostName}
                  music         IN CNAME ${reverseProxyHostName}
                  news          IN CNAME ${reverseProxyHostName}
                  prometheus    IN CNAME ${reverseProxyHostName}
                  prowlarr      IN CNAME ${reverseProxyHostName}
                  push          IN CNAME ${reverseProxyHostName}
                  radarr        IN CNAME ${reverseProxyHostName}
                  readlater     IN CNAME ${reverseProxyHostName}
                  shared.album  IN CNAME ${reverseProxyHostName}
                  sonarr        IN CNAME ${reverseProxyHostName}
                  status        IN CNAME ${reverseProxyHostName}
                  torrents      IN CNAME ${reverseProxyHostName}
                  vault         IN CNAME ${reverseProxyHostName}
                '';
              in
              ''
                ${domainName}:53 {
                  errors
                  log stdout
                  bind ${cfg.bindInterface}
                  file ${zoneFile}
                }
                ${tailnetDomainName}:53 {
                  errors
                  log stdout
                  bind ${cfg.bindInterface}
                  forward . 100.100.100.100:53
                }
                .:53 {
                  errors
                  log stdout
                  bind ${cfg.bindInterface}
                  forward . ${if cfg.blocking.enable then cfg.blocking.listenAddress else "1.1.1.1:53"}
                }
              '';
          };

          services.blocky = {
            enable = cfg.blocking.enable;
            settings = {
              ports = {
                dns = cfg.blocking.listenAddress;
                # Wildcard bind: reachable over the tailnet via tailscaled's
                # ts-input chain for Prometheus scraping; the default-deny
                # firewall keeps it closed on eth0 (do NOT open it).
                http = ":${toString facts.services.blocky.port}";
              };
              upstreams.groups.default = [
                "1.1.1.1"
                "1.0.0.1"
              ];
              # Resolve blocklist URLs without depending on the host resolver.
              bootstrapDns = "tcp+udp:1.1.1.1";
              blocking = {
                denylists.ads = [
                  # Hagezi Pro: balanced ads/tracking/telemetry list (plain-domain format).
                  "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/domains/pro.txt"
                ];
                # To un-break a site, add an allowlists.ads entry mirroring the shape above.
                clientGroupsBlock.default = [ "ads" ];
                loading = {
                  # Serve DNS immediately at boot; lists load/refresh in the background.
                  strategy = "fast";
                  refreshPeriod = "24h";
                };
              };
              prometheus.enable = true; # /metrics on the http port
              # Ship the query log to PostgreSQL on site-jp
              # (selfhosted-blocky-query-log): Grafana charts top
              # queried/blocked domains from it. Writes are batched (30s
              # flush) and pruned after logRetentionDays. If the database is
              # unreachable at startup, blocky retries 3x2s and then falls
              # back to console logging: DNS never depends on site-jp being
              # up (which is also why creationAttempts stays at its low
              # default: the retry loop blocks startup).
              queryLog =
                let
                  ql = facts.services.blocky.query-log;
                in
                {
                  type = "postgresql";
                  # sslmode=disable: the server does not offer TLS; skip the
                  # doomed negotiation attempt.
                  target = "postgres://${ql.user}@${ql.host}:${toString ql.port}/${ql.database}?sslmode=disable";
                  logRetentionDays = 30;
                };
            };
          };

          # Give the query-log writer a tailnet route at boot; without it the
          # initial connection attempts race tailscaled and blocky silently
          # falls back to console logging until restarted.
          systemd.services.blocky = lib.mkIf cfg.blocking.enable {
            after = [
              "tailscaled.service"
              "tailscaled-autoconnect.service"
            ];
          };

          systemd.services.coredns = {
            after = [
              "tailscaled.service"
              "tailscaled-autoconnect.service"
            ];
            unitConfig.Requires = [ "tailscaled.service" ];
            serviceConfig.RestartSec = "5s";
          };
        };
    };
}
