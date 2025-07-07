{
  lib,
  pkgs,
  usrlib,
  ...
} @ args: let
  isNasPrimary = usrlib.bool.isTrue (usrlib.hm.getUserConfig args).modules.system.roles.nas.primary;
in {
  systemd.user.timers.backup-beans = lib.mkIf isNasPrimary {
    Unit.Description = "Backup financial information from remote";
    Install.WantedBy = ["timers.target"];
    Timer = {
      OnCalendar = "hourly";
      Persistent = true;
    };
  };

  systemd.user.services.backup-beans = lib.mkIf isNasPrimary {
    Unit.Description = "Backup financial information from remote";
    Install.WantedBy = ["default.target"];
    Service = {
      Type = "oneshot";
      IOSchedulingClass = "idle";
      ExecStart = let
        backup-ssh-key = args.osConfig.age.secrets."keys/beans_backup_ed25519_key".path;
        backup-ssh-options = "-o IdentitiesOnly=yes -o IdentityFile=${backup-ssh-key} -o PasswordAuthentication=no";
        backup-beans = pkgs.writeShellApplication {
          name = "backup-beans";
          runtimeInputs = with pkgs; [rsync openssh coreutils];
          # The `beans/` directory is not mentioned explicitly because it is
          # configured on the receiver's end via `rrsync -ro ~/beans`.
          text = ''
            rsync -avz --stats --progress \
              --exclude="lost+found" \
              --exclude=".direnv" \
              --exclude=".git" \
              --delete \
              --rsh "ssh -l delay -F /dev/null ${backup-ssh-options}" \
              linode.neko-danio.ts.net: /tank/delay/beans/
          '';
        };
      in
        lib.getExe backup-beans;
    };
  };
}
