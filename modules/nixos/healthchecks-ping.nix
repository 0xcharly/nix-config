{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.modules.system.healthchecks.ping;
in {
  config = lib.mkIf cfg.enable {
    systemd = {
      timers."healthchecks-ping" = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnBootSec = "5m";
          OnUnitActiveSec = "5m";
          Unit = "healthchecks-ping.service";
        };
      };

      services."healthchecks-ping" = {
        script = lib.getExe (pkgs.writeShellApplication {
          name = "healthchecks-ping";
          runtimeInputs = with pkgs; [runitor];
          text = ''
            runitor \
              -api-url "https://healthchecks.qyrnl.com/ping" \
              -uuid "file:${cfg.keyFile}" \
              -- date -Iseconds
          '';
        });
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
      };
    };
  };
}
