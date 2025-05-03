{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.system.roles.nas;
in
  lib.mkIf cfg.enable {
    users.users.zrepl = {
      isSystemUser = true;
      home = "/var/lib/zrepl";
      shell = "/bin/sh";
      createHome = true;
      group = "zrepl";
      openssh.authorizedKeys.keys = lib.mkIf (!cfg.primary) [
        ''command="zrepl stdinserver",restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIf1BY82EBfuIPmqzPhA0SXNRQ9z7zdCzE99TiqdjWmg''
      ];
    };

    users.groups.zrepl = {};

    services.zrepl = {
      enable = true;
      settings = {
        jobs = [
          # Sender.
          (lib.mkIf cfg.primary {
            name = "send";
            type = "push";
            connect = {
              type = "ssh+stdinserver";
              host = "selene.neko-danio.ts.net";
              port = 22;
              user = "zrepl";
              identity_file = config.age.secrets."keys/zrepl_ed25519_key".path;
            };
            filesystems = let
              datasets = [
                "ayako/files"
                "ayako/media"
                "backups/ayako"
                "backups/dad"
                "backups/delay"
                "delay/beans"
                "delay/files"
                "delay/media"
              ];
            in
              lib.mergeAttrsList (builtins.map (dataset: {
                  "tank/${dataset}<" = true;
                })
                datasets);
            snapshotting = {
              type = "periodic";
              interval = "24h";
              prefix = "zrepl_";
            };
            pruning = {
              keep_sender = [
                {
                  type = "regex";
                  regex = "^manual_.*";
                }
                {
                  type = "grid";
                  grid = "1x24h(keep=7)";
                  regex = "^zrepl_.*";
                }
                {
                  type = "last_n";
                  count = 5;
                }
              ];
              keep_receiver = [
                {
                  type = "regex";
                  regex = "^manual_.*";
                }
                {
                  type = "grid";
                  grid = "1x24h(keep=14)";
                  regex = "^zrepl_.*";
                }
                {
                  type = "last_n";
                  count = 5;
                }
              ];
            };
          })
          # Receiver(s).
          (lib.mkIf (!cfg.primary) {
            name = "recv";
            type = "sink";
            serve.type = "stdinserver";
            root_fs = ""; # Leave empty to write directly to the same datasets as the sender.
          })
        ];
      };
    };

    systemd.services.zrepl = {
      after = ["network-online.target" "tailscaled.service"];
      requires = ["network-online.target" "tailscaled.service"];
      wants = ["tailscaled.service"];
    };

    systemd.services.zreplZfsPermissions = {
      description = "Delegate ZFS permissions to the zrepl user";
      wantedBy = ["multi-user.target"];
      after = ["zfs.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = let
          permissions =
            if cfg.primary
            then "send,receive,snapshot,hold,release,mount"
            else "receive,mount";
          zreplZfsAllow = pkgs.writeShellApplication {
            name = "zrepl-zfs-allow";
            runtimeInputs = with pkgs; [zfs];
            text = ''
              for dataset in $(zfs list -H -o name -r tank); do
                echo "Setting ZFS permissions for $dataset…"
                zfs allow -u zrepl ${permissions} "$dataset"
              done
            '';
          };
        in
          lib.getExe zreplZfsAllow;
      };
    };
  }
