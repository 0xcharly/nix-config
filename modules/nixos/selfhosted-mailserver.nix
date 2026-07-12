{ self, inputs, ... }:
{
  flake.nixosModules.selfhosted-mailserver =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.node.services.mailserver;
      inherit (self.lib) facts gatus;

      mkPushRequest =
        success:
        gatus.mkPushBasedExternalPostRequest {
          inherit pkgs success;
          domain = facts.services.gatus.domain;
          tokenFile = config.age.secrets."services/gatus-external-endpoints.token".path;
          group = "cron";
          endpoint = "Mail retention purge";
        };

      reportResult = self.lib.builders.mkShellApplication pkgs {
        name = "mailserver-retention-report-result";
        text = ''
          if [ "''${SERVICE_RESULT:-}" = "success" ]; then
            exec ${lib.getExe (mkPushRequest true)}
          else
            exec ${lib.getExe (mkPushRequest false)}
          fi
        '';
      };
    in
    {
      imports = [
        inputs.simple-nixos-mailserver.nixosModule
      ];

      options.node.services.mailserver = with lib; {
        enable = mkEnableOption "a self-hosted, private mailserver";
      };

      config = lib.mkIf cfg.enable {
        mailserver = {
          inherit (cfg) enable;
          stateVersion = 5;

          inherit (facts.mail) fqdn domains;
          systemDomain = "delay.email";

          accounts."delay" = {
            hashedPasswordFile = config.age.secrets."services/mail/delay.passwd".path;
            # "@<domain>" = catch-all for the domain + permission to send from
            # any address in it.
            aliases = map (domain: "@${domain}") facts.mail.domains;
          };

          indexDir = "/var/mail/index";
          fullTextSearch = {
            enable = true;
            languages = [
              "en"
              "fr"
            ];
            # No "stopwords" (upstream default): with multiple languages
            # configured it makes some searches fail (SNM warns about it).
            filters = [
              "normalizer-icu"
              "snowball"
            ];
          };

          storage = {
            uid = 3000;
            gid = 3000;
            owner = "mail";
            group = "mail";
            path = "/var/mail/boxes";
          };

          dkim.keyDirectory = "/var/mail/dkim";

          useUTF8FolderNames = true;
          hierarchySeparator = "/";

          # IMAPS :993 and Submissions :465 are on by default (enableImapSsl /
          # enableSubmissionSsl); openFirewall defaults to true.

          x509.useACMEHost = config.mailserver.fqdn;
        };

        # TLS certificate for the mailserver FQDN via ACME HTTP-01.
        security.acme = {
          acceptTerms = true;
          defaults.email = "postmaster@delay.email";
        };
        services.nginx = {
          inherit (cfg) enable;
          virtualHosts.${config.mailserver.fqdn}.enableACME = true;
        };
        networking.firewall.allowedTCPPorts = [ 80 ]; # HTTP-01 challenge

        # Retention: the archive on site-jp pulls every 30 minutes; anything
        # older than 30 days (and not flagged) is expunged from the hot server.
        systemd.services.mailserver-retention = {
          description = "Expunge mail older than 30 days (excluding flagged)";
          script = ''
            ${lib.getExe' config.services.dovecot2.package "doveadm"} \
              expunge -u delay mailbox '*' savedbefore 30d not flagged
          '';
          serviceConfig = {
            Type = "oneshot";
            # "+" runs the hook as root: the Gatus token file is root-readable
            # only, and $SERVICE_RESULT covers every outcome.
            ExecStopPost = "+${reportResult}";
          };
          # Daily, UTC; the archive runs every 30 min, so mail is at most
          # 30 min un-archived when purged.
          startAt = "03:30";
        };
      };
    };
}
