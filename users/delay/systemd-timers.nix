{
  lib,
  pkgs,
  osConfig,
  ...
}: let
  isNasPrimary = osConfig.modules.system.roles.nas.primary;
in {
  systemd.user.timers."backup-beans" = lib.mkIf isNasPrimary {
    Unit.Description = "Backup financial information from remote";
    Install.WantedBy = ["timers.target"];
    Timer = {
      OnCalendar = "hourly";
      Persistent = true;
    };
  };

  # This setting ensures Home Manager uses `systemctl --user switch` during
  # activation, which both:
  #
  # - Enables systemd user units (via symlinks)
  # - Starts or restarts them as needed — including timers — without requiring
  #   manual start or enable
  #
  # NOTE: The default for HM 24.11 is "suggest" or `false`, but this changed on
  # `master` (and thus will be changed in 25.05) for "sd-switch" or `true`.
  # TODO(25.05): Remove this as it is now the default.
  systemd.user.startServices = "sd-switch";

  systemd.user.services."backup-beans" = lib.mkIf isNasPrimary {
    Unit.Description = "Backup financial information from remote";
    Install.WantedBy = ["default.target"];
    Service = {
      Type = "oneshot";
      IOSchedulingClass = "idle";
      ExecStart = let
        backup-ssh-key = osConfig.age.secrets."keys/beans_backup_ed25519_key".path;
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
              linode.neko-danio.ts.net: /tank/delay/beans/
          '';
        };
      in
        lib.getExe backup-beans;
    };
  };
}
