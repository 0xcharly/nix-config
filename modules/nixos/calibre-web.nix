{
  config,
  lib,
  ...
}: let
  cfg = config.node.services.calibre;
in {
  options.node.services.calibre.enable = lib.mkEnableOption "Whether to spin up a Kavita service.";

  config = {
    services = {
      calibre-web = {
        inherit (cfg) enable;
        listen.ip = "0.0.0.0";
        options = {
          enableBookUploading = true;
          enableBookConversion = true;
          enableKepubify = true;
          calibreLibrary = "/tank/delay/media/books";
        };
      };

      gatus.settings.endpoints = [
        (lib.fn.mkHttpServiceEndpoint "calibre-web" "reads.qyrnl.com")
      ];

      caddy.virtualHosts = lib.mkIf config.node.services.reverseProxy.enable {
        "reads.qyrnl.com".extraConfig = ''
          import ts_host
          reverse_proxy helios.qyrnl.com:${toString config.services.calibre-web.listen.port}
        '';
      };
    };

    # Wait for ZFS datasets to be mounted to start the web server.
    systemd.services.calibre-web = lib.mkIf cfg.enable {
      after = ["local-fs.target" "zfs-mount.service"];
      wants = ["zfs-mount.service"];
    };
  };
}
