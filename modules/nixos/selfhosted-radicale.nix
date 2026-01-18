{ flake, ... }:
{
  config,
  lib,
  ...
}:
{
  options.node.services.radicale = with lib; {
    enable = mkEnableOption "Spin up a Radicale (CalDAV & CardDAV) service";
  };

  config =
    let
      cfg = config.node.services.radicale;
      inherit (flake.lib) facts;
    in
    {
      node.fs.zfs.zpool.root.datadirs = lib.mkIf cfg.enable {
        radicale = {
          owner = "radicale";
          group = "radicale";
          mode = "0700";
        };
      };

      services.radicale = {
        inherit (cfg) enable;
        settings = {
          server.hosts = [
            "0.0.0.0:${toString facts.services.radicale.port}"
            "[::]:${toString facts.services.radicale.port}"
          ];
          auth = {
            type = "htpasswd";
            htpasswd_filename = config.age.secrets."services/radicale.htpasswd".path;
            htpasswd_encryption = "autodetect";
          };
          storage.filesystem_folder = "${config.node.fs.zfs.zpool.root.datadirs.radicale.absolutePath}/collections";
        };
        rights = {
          root = {
            user = ".+";
            collection = "";
            permissions = "R";
          };
          principal = {
            user = ".+";
            collection = "{user}";
            permissions = "RW";
          };
          calendars = {
            user = ".+";
            collection = "{user}/[^/]+";
            permissions = "rw";
          };
        };
      };
    };
}
