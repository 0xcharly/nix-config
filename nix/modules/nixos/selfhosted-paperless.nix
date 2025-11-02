{
  flake,
  inputs,
  ...
}: {
  config,
  lib,
  ...
}: {
  imports = [
    inputs.nix-config-secrets.modules.nixos.services-paperless
  ];

  options.node.services.paperless = with lib; {
    enable = mkEnableOption "Spin up a Paperless-ngx service";
  };

  config = let
    cfg = config.node.services.paperless;
    inherit (flake.lib) caddy facts gatus;
  in {
    node.fs.zfs.zpool.root.datadirs = lib.mkIf cfg.enable {
      paperless = {
        owner = config.services.paperless.user;
        group = config.services.paperless.user;
        mode = "0755";
      };
      redis-paperless = {
        owner = config.services.redis.servers.paperless.user;
        group = config.services.redis.servers.paperless.group;
        mode = "0700";
      };
    };

    services = {
      paperless = {
        inherit (cfg) enable;
        dataDir = config.node.fs.zfs.zpool.root.datadirs.paperless.absolutePath;
        address = "0.0.0.0";
        configureTika = true;
        mediaDir = "/tank/delay/files";
        passwordFile = config.age.secrets."services/paperless-admin-passwd".path;
        settings = {
          PAPERLESS_URL = "https://${facts.services.paperless.domain}";
          PAPERLESS_CONSUMER_IGNORE_PATTERN = [
            ".DS_STORE/*"
            "desktop.ini"
          ];
          PAPERLESS_OCR_LANGUAGE = "eng+fra+jpn";
          PAPERLESS_OCR_USER_ARGS = {
            optimize = 1;
            pdfa_image_compression = "lossless";
          };
        };
      };

      caddy.virtualHosts = caddy.mkReverseProxyConfig facts.services.paperless;
      gatus.settings.endpoints = [
        (gatus.mkHttpServiceCheck "paperless" facts.services.paperless)
      ];
    };
  };
}
