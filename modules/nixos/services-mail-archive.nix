{ self, ... }:
{
  flake.nixosModules.services-mail-archive =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (self.lib) facts gatus;

      mkPushRequest =
        success:
        gatus.mkPushBasedExternalPostRequest {
          inherit pkgs success;
          domain = facts.services.gatus.domain;
          tokenFile = config.age.secrets."services/gatus-external-endpoints.token".path;
          group = "cron";
          endpoint = "Mail archive";
        };

      reportResult = self.lib.builders.mkShellApplication pkgs {
        name = "mail-archive-report-result";
        text = ''
          if [ "''${SERVICE_RESULT:-}" = "success" ]; then
            exec ${lib.getExe (mkPushRequest true)}
          else
            exec ${lib.getExe (mkPushRequest false)}
          fi
        '';
      };

      # Pull-only archive: new mail and flag updates are pulled; deletions
      # (the jump-jp 30-day purge) are NEVER propagated to the archive.
      mbsyncConfig = pkgs.writeText "mbsyncrc" ''
        IMAPAccount jump-jp
        Host ${facts.mail.fqdn}
        Port 993
        User delay
        PassCmd "cat ${config.age.secrets."services/mail-archive/delay.passwd".path}"
        TLSType IMAPS

        IMAPStore remote
        Account jump-jp

        MaildirStore local
        Path /tank/delay/email/
        Inbox /tank/delay/email/INBOX
        SubFolders Verbatim

        Channel archive
        Far :remote:
        Near :local:
        Patterns *
        Create Near
        Sync PullNew PullFlags
        Expunge None
        CopyArrivalDate yes
        SyncState *
      '';
    in
    {
      options.node.services.mail-archive = with lib; {
        enable = mkEnableOption "the mail archival job (mbsync pull from the mailserver)";
      };

      config = lib.mkIf config.node.services.mail-archive.enable {
        systemd.services.mail-archive = {
          description = "Archive mail from ${facts.mail.fqdn} to /tank/delay/email";

          # Never write to an unmounted /tank (would land on the root dataset).
          after = [ "zfs-mount-tank.service" ];
          requires = [ "zfs-mount-tank.service" ];
          unitConfig.ConditionPathIsMountPoint = "/tank/delay/email";

          script = ''
            ${lib.getExe' pkgs.isync "mbsync"} -c ${mbsyncConfig} -a
          '';

          serviceConfig = {
            Type = "oneshot";
            User = "delay";
            # "+" runs the hook as root: the Gatus token file is root-readable
            # only, and $SERVICE_RESULT covers every outcome.
            ExecStopPost = "+${reportResult}";
          };
          startAt = "*:0/30"; # every 30 minutes
        };
      };
    };
}
