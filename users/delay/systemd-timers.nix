{
  lib,
  pkgs,
  usrlib,
  ...
} @ args: let
  isNasPrimary = usrlib.bool.isTrue (usrlib.hm.getUserConfig args).modules.system.roles.nas.primary;
in {
  systemd.user.timers."backup-beans" = lib.mkIf isNasPrimary {
    Unit.Description = "Backup financial information from remote";
    Install.WantedBy = ["timers.target"];
    Timer = {
      OnCalendar = "hourly";
      Persistent = true;
    };
  };

  systemd.user.services."backup-beans" = lib.mkIf isNasPrimary {
    Unit.Description = "Backup financial information from remote";
    Install.WantedBy = ["default.target"];
    Service = {
      Type = "oneshot";
      IOSchedulingClass = "idle";
      ExecStart = let
        backup-ssh-key = args.osConfig.age.secrets."keys/beans_backup_ed25519_key".path;
        backup-beans = pkgs.writeShellApplication {
          name = "backup-beans";
          runtimeInputs = with pkgs; [rsync openssh coreutils];
          # The `beancount/` directory is excluded because it is configured on
          # the receiver's end via `rrsync -ro ~/beancount`.
          # TODO: convert the receiver to NixOS so this config can be checked in
          # and kept in sync.
          text = ''
            rsync -avz --stats --progress \
              --exclude="lost+found" \
              --exclude=".direnv" \
              --exclude=".git" \
              --delete \
              --rsh "ssh -l delay -F /dev/null -o IdentitiesOnly=yes -o IdentityFile=${backup-ssh-key} -o PasswordAuthentication=no" \
              linode-arch.neko-danio.ts.net: /tank/delay/beans/
          '';
        };
      in
        lib.getExe backup-beans;
    };
  };
}
