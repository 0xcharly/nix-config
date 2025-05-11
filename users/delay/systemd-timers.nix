{
  config,
  lib,
  pkgs,
  ...
}: let
  isNasPrimary = lib.mkIf config.modules.system.roles.nas.primary;
in {
  systemd.user.timers."backup-beans" = lib.mkIf isNasPrimary {
    Unit.Description = "Backup financial information from remote";
    Install.WantedBy = ["timers.target"];
    Timer = {
      OnStartupSec = "1h";
      OnUnitActiveSec = "1h";
    };
  };

  systemd.user.services."backup-beans" = lib.mkIf isNasPrimary {
    Unit.Description = "Backup financial information from remote";
    Service = {
      Type = "oneshot";
      IOSchedulingClass = "idle";
      ExecStart = pkgs.writeShellApplication {
        name = "backup-beans";
        runtimeInputs = with pkgs; [rsync];
        text = ''
          rsync -avz --stats --progress \
            --exclude="lost+found" \
            --exclude=".direnv" \
            --exclude=".git" \
            --delete \
            linode.neko-danio.ts.net:beancount/ /tank/delay/beans/
        '';
      };
    };
  };
}
