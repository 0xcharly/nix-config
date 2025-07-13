{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.system.services.serve;
in
  lib.mkIf cfg.reverseProxy {
    services.caddy = {
      enable = true;
      # TODO: switch to `pkgs.caddy.withPlugins` when possible. Currently
      # doesn't build because of libdns 1.0 release and breaking changes.
      # Uses a custom build in the meantime.
      package = pkgs.caddy-gandi;
      # package = pkgs.caddy.withPlugins {
      #   plugins = ["github.com/libdns/gandi@v1.0.4"];
      #   hash = "sha256-cSjFzPw1YcvQQDnv1fLCbKHe+b/tyTqQG89dIH1DI+k=";
      # };
      environmentFile = config.age.secrets."services/gandi-creds".path;
      virtualHosts = {
        "(ts_host)".extraConfig = ''
            tls {
              resolvers 1.1.1.1
              dns gandi {env.GANDIV5_PERSONAL_ACCESS_TOKEN}
            }
        '';
        "vault.qyrnl.com" = lib.mkIf cfg.vaultwarden {
          extraConfig = ''
            import ts_host
            reverse_proxy localhost:${toString config.services.vaultwarden.config.ROCKET_PORT}
          '';
        };
        "atuin.qyrnl.com" = lib.mkIf cfg.atuin {
          extraConfig = ''
            import ts_host
            reverse_proxy localhost:${toString config.services.atuin.port}
          '';
        };
      };
    };

    # Allow Caddy to bind to 443.
    systemd.services.caddy.serviceConfig = {
      AmbientCapabilities = ["CAP_NET_BIND_SERVICE"];
      EnvironmentFile = config.age.secrets."services/gandi-creds".path;
    };
  }
