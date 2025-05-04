{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.system.roles.nas;
  username = "backups";
  group = "backups";
in
  lib.mkIf cfg.enable {
    users.users."${username}" = {
      isSystemUser = true;
      home = "/var/lib/${username}";
      shell = "/usr/sbin/nologin";
      createHome = true;
      inherit group;
      openssh.authorizedKeys.keys = lib.mkIf (!cfg.primary) [
        ''command="${pkgs.sanoid}/bin/syncoid",restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIf1BY82EBfuIPmqzPhA0SXNRQ9z7zdCzE99TiqdjWmg''
      ];
    };

    users.groups."${group}" = {};

    environment.systemPackages = with pkgs; [
      mbuffer
      sanoid
    ];

    systemd.services.sanoid = {
      after = ["network-online.target" "tailscaled.service" "zfs-mount-tank.service"];
      requires = ["network-online.target" "tailscaled.service" "zfs-mount-tank.service"];
      wants = ["tailscaled.service"];
    };

    systemd.services."${username}ZfsPermissions" = {
      description = "Delegate ZFS permissions to the `${username}` user";
      wantedBy = ["multi-user.target"];
      after = ["zfs.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = let
          permissions =
            if cfg.primary
            then "send,receive,snapshot,hold,release,mount"
            else "receive,mount";
          zfsAllow = pkgs.writeShellApplication {
            name = "${username}-zfs-allow";
            runtimeInputs = with pkgs; [zfs];
            text = ''
              for dataset in $(zfs list -H -o name -r tank); do
                echo "Setting ZFS permissions for $dataset…"
                zfs allow -u ${username} ${permissions} "$dataset"
              done
            '';
          };
        in
          lib.getExe zfsAllow;
      };
    };
  }
