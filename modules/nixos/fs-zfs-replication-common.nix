{
  config,
  lib,
  pkgs,
  ...
}: {
  options.node.fs.zfs.replication = with lib; {
    permissions = mkOption {
      type = types.listOf types.str;
      description = ''
        List of ZFS permissions to grant the `syncoid` user.
      '';
    };
  };

  config = let
    cfg = config.node.fs.zfs.replication;
  in {
    environment.systemPackages = with pkgs; [
      mbuffer # Syncoid optimization to smooth out network transfers
      lzop # Syncoid optimization to reduce bytes transfered
      sanoid
    ];

    systemd.services."syncoid-zfs-permissions" = {
      description = "Delegate ZFS permissions to the `syncoid` user";
      wantedBy = ["multi-user.target"];
      after = ["zfs.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = let
          permissions = lib.concatStringsSep "," cfg.permissions;
          syncoid-zfs-allow = with pkgs;
            writeShellApplication {
              name = "syncoid-zfs-allow";
              runtimeInputs = [config.boot.zfs.package];
              text = ''
                for dataset in $(zfs list -H -o name -r tank); do
                  echo "Setting ZFS permissions for $dataset…"
                  zfs allow -u syncoid ${permissions} "$dataset"
                done
              '';
            };
        in
          lib.getExe syncoid-zfs-allow;
      };
    };
  };
}
