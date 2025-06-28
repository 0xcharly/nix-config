{
  lib,
  pkgs,
  usrlib,
  ...
} @ args: let
  config = usrlib.hm.getUserConfig args;
  cfg = config.modules.system;
  isNasPrimary = usrlib.bool.isTrue cfg.roles.nas.primary;
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
        remoteHost = "${cfg.beans.sourceOfTruthHostName}.${config.node.facts.tailscale.tailnetName}";
        backup-ssh-key = args.osConfig.age.secrets."keys/beans_backup_ed25519_key".path;
        backup-ssh-options = "-o IdentitiesOnly=yes -o IdentityFile=${backup-ssh-key} -o PasswordAuthentication=no";
        backup-beans = pkgs.writeShellApplication {
          name = "backup-beans";
          runtimeInputs = with pkgs; [rsync openssh coreutils];
          # The `beans/` directory is not mentioned explicitly because it is
          # configured on the receiver's end via `rrsync -ro ~/beans`.
          text = ''
            rsync -avz --stats --progress \
              --exclude=".direnv" \
              --exclude=".envrc" \
              --exclude=".git" \
              --exclude="flake.nix" \
              --exclude="flake.lock" \
              --delete \
              --rsh "ssh -l ${cfg.beans.user} -F /dev/null ${backup-ssh-options}" \
              ${remoteHost}: /tank/delay/beans/
          '';
        };
      in
        lib.getExe backup-beans;
    };
  };
}
