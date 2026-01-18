{ flake, ... }:
{
  config,
  lib,
  ...
}:
{
  options.node.services.navidrome = with lib; {
    enable = mkEnableOption "Spin up a Navidrome service";
  };

  config =
    let
      cfg = config.node.services.navidrome;
      inherit (flake.lib) facts;
    in
    {
      node.fs.zfs.zpool.root.datadirs = lib.mkIf cfg.enable {
        navidrome = {
          owner = config.services.navidrome.user;
          group = config.services.navidrome.group;
          mode = "0755";
        };
      };

      services = {
        navidrome = {
          inherit (cfg) enable;
          settings = {
            Address = "0.0.0.0";
            BaseUrl = "https://${facts.services.navidrome.domain}";
            Port = facts.services.navidrome.port;
            DataFolder = config.node.fs.zfs.zpool.root.datadirs.navidrome.absolutePath;
            MusicFolder = "/tank/delay/music";
            EnableInsightsCollector = false;
          };
        };
      };

      # Wait for ZFS datasets to be mounted to start the service.
      systemd.services.navidrome = lib.mkIf cfg.enable {
        after = [
          "local-fs.target"
          "zfs-mount.service"
          "zfs-mount-tank.service"
        ];
        wants = [ "zfs-mount-tank.service" ];
      };
    };
}
