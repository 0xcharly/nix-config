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
        # TODO: define Immich's host and port somewhere else.
        # TODO: define flag to enable this virtual host.
        "album.qyrnl.com" = {
          extraConfig = ''
            import ts_host
            reverse_proxy helios.neko-danio.ts.net:2283
          '';
        };
        # TODO: define IPP's host and port somewhere else.
        # TODO: define flag to enable this virtual host.
        "shared.album.qyrnl.com" = {
          extraConfig = ''
            import ts_host
            reverse_proxy helios.neko-danio.ts.net:3000
          '';
        };
        "atuin.qyrnl.com" = lib.mkIf cfg.atuin {
          extraConfig = ''
            import ts_host
            reverse_proxy localhost:${toString config.services.atuin.port}
          '';
        };
        # TODO: define Jellyfin's host and port somewhere else.
        "jellyfin.qyrnl.com" = lib.mkIf cfg.atuin {
          extraConfig = ''
            import ts_host
            reverse_proxy helios.neko-danio.ts.net:8096
          '';
        };
        "healthchecks.qyrnl.com" = lib.mkIf cfg.healthchecks {
          extraConfig = ''
            import ts_host
            reverse_proxy localhost:${toString config.services.healthchecks.port}
          '';
        };
        "push.qyrnl.com" = lib.mkIf cfg.gotify {
          extraConfig = ''
            import ts_host
            reverse_proxy localhost:${toString config.services.gotify.environment.GOTIFY_SERVER_PORT}
          '';
        };
        "tasks.qyrnl.com" = lib.mkIf cfg.taskchampion-sync-server {
          extraConfig = ''
            import ts_host
            reverse_proxy localhost:${toString config.services.taskchampion-sync-server.port}
          '';
        };
        "vault.qyrnl.com" = lib.mkIf cfg.vaultwarden {
          extraConfig = ''
            import ts_host
            reverse_proxy localhost:${toString config.services.vaultwarden.config.ROCKET_PORT}
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
