{
  config,
  lib,
  ...
}: let
  cfg = config.node.services.paperless;
in {
  options.node.services.paperless.enable = lib.mkEnableOption "Whether to spin up a Paperless-ngx server.";

  config.services = {
    paperless = {
      inherit (cfg) enable;
      address = "0.0.0.0";
      configureTika = true;
      mediaDir = "/tank/delay/files";
      passwordFile = config.age.secrets."services/paperless-admin-passwd".path;
      settings = {
        PAPERLESS_URL = "https://files.qyrnl.com";
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

    # TODO: define Paperless' host somewhere else.
    caddy.virtualHosts."files.qyrnl.com" = {
      extraConfig = ''
        import ts_host
        reverse_proxy helios.qyrnl.com:${toString config.services.paperless.port}
      '';
    };
  };
}
