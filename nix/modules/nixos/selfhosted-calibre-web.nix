{flake, ...}: {
  config,
  lib,
  ...
}: {
  options.node.services.calibre = with lib; {
    enable = mkEnableOption "Spin up a Calibre Web service";
  };

  config = let
    cfg = config.node.services.calibre;
    inherit (flake.lib) caddy facts gatus;
  in {
    node = lib.mkIf cfg.enable {
      fs.zfs.zpool.root.datadirs.calibre-web = {};
    };

    services = {
      calibre-web = {
        inherit (cfg) enable;
        dataDir = config.node.fs.zfs.zpool.root.datadirs.calibre-web.absolutePath;
        listen = {
          ip = "0.0.0.0";
          inherit (facts.services.calibre-web) port;
        };
        options = {
          enableBookUploading = true;
          enableBookConversion = true;
          enableKepubify = true;
          calibreLibrary = "/tank/delay/media/books";
        };
      };

      caddy.virtualHosts = caddy.mkReverseProxyConfig facts.services.calibre-web;
      gatus.settings.endpoints = [
        (gatus.mkHttpServiceCheck "calibre-web" facts.services.calibre-web)
      ];
    };
  };
}
