{
  config,
  inputs,
  lib,
  usrlib,
  pkgs,
  ...
}: let
  isNasPrimary = usrlib.bool.isTrue config.modules.system.roles.nas.primary;
in {
  imports = [inputs.golink.nixosModules.default];

  services.golink = {
    enable = config.modules.system.services.serve.golink;
    tailscaleAuthKeyFile = config.age.secrets."services/tailscale-preauth.key".path;
  };

  users.users = lib.mkIf config.services.golink.enable {
    "${config.services.golink.user}" = {
      extraGroups = ["tailscale"];
      openssh.authorizedKeys.keys = [
        # Authorize backups of go/link data dir.
        ''command="${lib.getExe pkgs.rrsync} -ro ${config.services.golink.dataDir}/" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGa3cDgdhUeqAP2Bmnew2/SfC6HiXslIUpyHQ8HsUUZO golink-backup''
      ];
    };
  };

  systemd.timers.backup-golink-service-data-dir = lib.mkIf isNasPrimary {
    Unit.Description = "Backup go/link server data directory";
    Install.WantedBy = ["timers.target"];
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  systemd.services.backup-golink-service-data-dir = lib.mkIf isNasPrimary {
    Unit.Description = "Backup go/link server data directory";
    Install.WantedBy = ["default.target"];
    Service = {
      Type = "oneshot";
      IOSchedulingClass = "idle";
      ExecStart = let
        backup-ssh-key = config.age.secrets."keys/golink_backup_ed25519_key".path;
        backup-ssh-options = "-o IdentitiesOnly=yes -o IdentityFile=${backup-ssh-key} -o PasswordAuthentication=no";
        backup-golink-service-data-dir = pkgs.writeShellApplication {
          name = "backup-golink-service-data";
          runtimeInputs = with pkgs; [rsync openssh coreutils];
          # The `dataDir` directory is not mentioned explicitly because it is
          # configured on the receiver's end via `rrsync -ro <dataDir>`.
          text = ''
            rsync -avz --stats --progress --delete \
              --rsh "ssh -l ${config.services.golink.user} -F /dev/null ${backup-ssh-options}" \
              heimdall.neko-danio.ts.net: /tank/backups/services/golink/
          '';
        };
      in
        lib.getExe backup-golink-service-data-dir;
    };
  };
}
