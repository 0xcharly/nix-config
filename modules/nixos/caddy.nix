{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.node.services.reverseProxy;
in {
  options.node.services.reverseProxy.enable = lib.mkEnableOption ''
    Whether to serve services from across the internal network
    behind a reverse proxy.
  '';

  config = lib.mkIf cfg.enable {
    services.caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = ["github.com/caddy-dns/gandi@v1.1.0"];
        hash = "sha256-JZLxPJd/HiM6I+YBHwLtQoMG2uZ92jKmlz5nQK6N5+U=";
      };
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
            reverse_proxy helios.qyrnl.com:${toString config.services.immich.port}
          '';
        };
        # TODO: define IPP's host and port somewhere else.
        # TODO: define flag to enable this virtual host.
        "shared.album.qyrnl.com" = {
          extraConfig = ''
            import ts_host
            reverse_proxy localhost:${toString config.services.immich-public-proxy.port}
          '';
        };
        "atuin.qyrnl.com" = {
          extraConfig = ''
            import ts_host
            reverse_proxy localhost:${toString config.services.atuin.port}
          '';
        };
        "files.qyrnl.com" = {
          extraConfig = ''
            import ts_host
            reverse_proxy helios.qyrnl.com:${toString config.services.paperless.port}
          '';
        };
        # TODO: define Jellyfin's host and port somewhere else.
        "jellyfin.qyrnl.com" = {
          extraConfig = ''
            import ts_host
            reverse_proxy helios.qyrnl.com:8096
          '';
        };
        "healthchecks.qyrnl.com" = {
          extraConfig = ''
            import ts_host
            reverse_proxy localhost:${toString config.services.healthchecks.port}
          '';
        };
        "push.qyrnl.com" = {
          extraConfig = ''
            import ts_host
            reverse_proxy localhost:${toString config.services.gotify.environment.GOTIFY_SERVER_PORT}
          '';
        };
        "status.qyrnl.com" = {
          extraConfig = ''
            import ts_host
            reverse_proxy localhost:${config.services.uptime-kuma.settings.PORT}
          '';
        };
        "tasks.qyrnl.com" = {
          extraConfig = ''
            import ts_host
            reverse_proxy localhost:${toString config.services.taskchampion-sync-server.port}
          '';
        };
        "vault.qyrnl.com" = {
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
  };
}
