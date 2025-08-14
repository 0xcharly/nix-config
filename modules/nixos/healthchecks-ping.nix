{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.node.healthchecks.ping;
in {
  options.node.healthchecks.ping = {
    enable = lib.mkEnableOption "Enable Healthchecks ping";
    keyFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        The path to the file containing the Healthcheck UUID.
      '';
    };
  };

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
