{ flake, ... }:
{
  imports = [ flake.modules.nixos.fs-zfs-replication-common ];

  config = {
    node.fs.zfs.replication.permissions = [
      "atime"
      "change-key"
      "compression"
      "create"
      "keylocation"
      "mount"
      "mountpoint"
      "receive"
      "recordsize"
      "rollback"
      "snapshot"
      "userprop"
    ];

    # Create service user on the replicas (it is automatically created on the sender side).
    # NOTE: Can't restrict access because syncoid needs to run multiple commands.
    users = {
      users.syncoid = {
        isSystemUser = true;
        home = "/var/lib/syncoid";
        useDefaultShell = true;
        createHome = true;
        group = "syncoid";
        openssh.authorizedKeys.keys = [
          ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIf1BY82EBfuIPmqzPhA0SXNRQ9z7zdCzE99TiqdjWmg''
        ];
      };

      groups.syncoid = { };
    };
  };
}
