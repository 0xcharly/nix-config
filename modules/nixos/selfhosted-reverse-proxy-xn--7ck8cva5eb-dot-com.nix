# Public (internet-facing) reverse proxy for チャーリー.com.
#
# Unlike selfhosted-reverse-proxy-qyrnl-dot-com (tailnet-bound), these
# virtual hosts bind gate-jp's public addresses. TLS uses Caddy's default
# HTTP-01/TLS-ALPN-01 challenges — the zone is self-hosted (coredns), so the
# Gandi DNS-01 plugin cannot be used, and none is needed since ports 80/443
# are publicly reachable.
#
# This module only adds virtual hosts; the shared Caddy plumbing (service
# enablement, CAP_NET_BIND_SERVICE, tailscale ordering) comes from
# selfhosted-reverse-proxy-preamble via `node.services.reverse-proxy`.
{ self, ... }:
{
  flake.nixosModules.selfhosted-reverse-proxy-xn--7ck8cva5eb-dot-com =
    { config, lib, ... }:
    let
      domainName = "xn--7ck8cva5eb.com"; # チャーリー.com
    in
    {
      options.node.services.reverse-proxy.${domainName} = with lib; {
        enable = mkEnableOption "Set up the public reverse proxy for ${domainName}";
        openFirewall = mkEnableOption "Open firewall ports for ${domainName}'s reverse proxy";

        bindInterface = mkOption {
          type = types.str;
          example = "eth0";
          description = "The public network interface to open the firewall on.";
        };
      };

      config =
        let
          cfg = config.node.services.reverse-proxy.${domainName};
          inherit (self.lib) caddy facts uri;
          inherit (facts.reverse-proxy.${domainName}) tmpl ipv4 ipv6;
        in
        {
          services.caddy = lib.mkIf cfg.enable {
            virtualHosts = {
              "(${tmpl})".extraConfig = ''
                bind ${ipv4} ${ipv6}
              '';

              # Apex only serves the public file share; everything else 404s.
              # `handle_path` strips the /public prefix before proxying to the
              # static-web-server root on site-jp. Caddy normalizes the URI
              # (dot-segment resolution) before matching, so `../` lookups
              # cannot escape the /public subtree.
              ${domainName}.extraConfig = ''
                import ${tmpl}
                handle_path /public/* {
                  reverse_proxy ${uri.mkAuthority { inherit (facts.services.public-files) host port; }}
                }
                redir /public /public/ 308
                handle {
                  respond 404
                }
              '';
            }
            // caddy.mkReverseProxyConfig (facts.services.immich-public-proxy // { import = tmpl; })
            # Convenience alias: https://public.チャーリー.com/{path} redirects
            # to the file share at https://チャーリー.com/public/{path}.
            // caddy.mkRedirectConfig {
              from = "public.${domainName}";
              to = "${domainName}/public";
              import = tmpl;
            };
          };

          networking.firewall = lib.mkIf (cfg.enable && cfg.openFirewall) {
            interfaces.${cfg.bindInterface}.allowedTCPPorts = [
              80 # ACME HTTP-01 challenge + HTTPS redirect
              443
            ];
          };
        };
    };
}
