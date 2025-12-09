{
  config,
  lib,
  ...
}: {
  options.node.services.jellyfin = with lib; {
    enable = mkEnableOption "Spin up a Jellyfin service";
  };

  config = let
    cfg = config.node.services.jellyfin;
  in {
    node.fs.zfs.zpool.root.datadirs = lib.mkIf cfg.enable {
      jellyfin = {
        owner = config.services.jellyfin.user;
        group = config.services.jellyfin.group;
        mode = "0700";
      };
    };

    services = {
      jellyfin = {
        inherit (cfg) enable;
        dataDir = config.node.fs.zfs.zpool.root.datadirs.jellyfin.absolutePath;
      };
    };
  };
}
