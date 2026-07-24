# Shared Caddy plumbing for the reverse-proxy modules
# (selfhosted-reverse-proxy-*-dot-com): those modules only contribute
# virtual hosts; this one owns service enablement, the transport policy,
# and the systemd ordering/capabilities every proxy needs.
_: {
  flake.nixosModules.selfhosted-reverse-proxy-preamble =
    { config, lib, ... }:
    {
      options.node.services.reverse-proxy = with lib; {
        enable = mkEnableOption "Spin up a reverse proxy service via Caddy";
      };

      config =
        let
          cfg = config.node.services.reverse-proxy;
        in
        lib.mkIf cfg.enable {
          services.caddy = {
            enable = true;
            # HTTP/3 has never been reachable here: the domain modules'
            # firewalls only open TCP 80/443, and QUIC datagrams from tailnet
            # clients exceed the tailscale0 MTU (1280) and fail client-side
            # with EMSGSIZE. Advertising `Alt-Svc: h3` breaks HTTP/3-capable
            # clients that trust it — notably python-caldav >= 2.2.5
            # (niquests), used by Errands, whose authenticated retry after a
            # 401 switches to h3 and aborts. Restrict Caddy to TCP protocols
            # so Alt-Svc is not emitted.
            globalConfig = ''
              servers {
                protocols h1 h2
              }
            '';
          };

          systemd.services.caddy = {
            # Tailnet-bound vhosts bind the tailscale IP, and the public ones
            # proxy to tailnet backends: Caddy cannot come up (or do anything
            # useful) before tailscaled.
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
        };
    };
}
