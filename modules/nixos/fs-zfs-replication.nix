{flake, ...}: {
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.node.fs.zfs.replication;
in {
  options.node.fs.zfs.replication = with lib; {
    primary = mkEnableOption "Whether this host is primary storage server";
  };

  config = {
    environment.systemPackages = with pkgs; [
      mbuffer # Syncoid optimization to smooth out network transfers.
      lzop # Syncoid optimization to reduce bytes transfered.
      sanoid
    ];

    # Create service user on the replicas (it is automatically created on the sender side).
    users = lib.mkIf (!cfg.primary) {
      users.syncoid = {
        isSystemUser = true;
        home = "/var/lib/syncoid";
        # NOTE: Can't restrict access because syncoid needs to run multiple commands.
        # shell = "${pkgs.util-linux}/bin/nologin";
        useDefaultShell = true;
        createHome = true;
        group = "syncoid";
        openssh.authorizedKeys.keys = [
          ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIf1BY82EBfuIPmqzPhA0SXNRQ9z7zdCzE99TiqdjWmg''
          # ''command="${pkgs.sanoid}/bin/syncoid",restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIf1BY82EBfuIPmqzPhA0SXNRQ9z7zdCzE99TiqdjWmg''
        ];
      };

      groups.syncoid = {};
    };

    systemd.services = lib.mkIf (!cfg.primary) {
      "syncoid-zfs-permissions" = {
        description = "Delegate ZFS permissions to the `syncoid` user";
        wantedBy = ["multi-user.target"];
        after = ["zfs.target"];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = let
            # The condition below is never true, but kept for documentation purposes.
            permissions = lib.concatStringsSep "," [
              "atime"
              "compression"
              "create"
              "keylocation"
              "mount"
              "mountpoint"
              "receive"
              "recordsize"
              "snapshot"
              "userprop"
            ];
            # NOTE: On the primary: "send,receive,snapshot,hold,release,mount"
          in
            flake.lib.builders.mkShellApplication pkgs {
              name = "syncoid-zfs-allow";
              runtimeInputs = with pkgs; [zfs];
              text = ''
                for dataset in $(zfs list -H -o name -r tank); do
                  echo "Setting ZFS permissions for $dataset…"
                  zfs allow -u syncoid ${permissions} "$dataset"
                done
              '';
            };
        };
      };
    };
  };
}
