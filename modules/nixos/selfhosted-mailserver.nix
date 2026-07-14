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
        group: endpoint: success:
        gatus.mkPushBasedExternalPostRequest {
          inherit
            pkgs
            success
            group
            endpoint
            ;
          domain = facts.services.gatus.domain;
          tokenFile = config.age.secrets."services/gatus-external-endpoints.token".path;
        };

      mkReportResult =
        name: group: endpoint:
        self.lib.builders.mkShellApplication pkgs {
          inherit name;
          text = ''
            if [ "''${SERVICE_RESULT:-}" = "success" ]; then
              exec ${lib.getExe (mkPushRequest group endpoint true)}
            else
              exec ${lib.getExe (mkPushRequest group endpoint false)}
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

          # Full address, not a bare login: the catch-all aliases resolve to
          # this name verbatim in postfix's virtual map, and a domainless
          # result gets $myorigin (mx.delay.email) appended — which is not a
          # served mail domain, so delivery relays to itself and bounces with
          # "mail for mx.delay.email loops back to myself".
          accounts."delay@delay.email" = {
            hashedPasswordFile = config.age.secrets."services/mail/delay.passwd".path;
            # "@<domain>" = catch-all for the domain + permission to send from
            # any address in it. The unicode-domains U-labels are included so
            # SMTPUTF8 submissions (client identity like mail@チャーリー.com)
            # pass reject_sender_login_mismatch — postfix looks the sender up
            # verbatim, without IDN normalization.
            aliases = map (domain: "@${domain}") (
              facts.mail.domains ++ lib.attrNames facts.mail.unicode-domains
            );
          };

          indexDir = "/var/lib/dovecot/indices";
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
          };

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

        # Canonicalize U-label (UTF-8) sender domains back to their A-label
        # form at submission: iOS Apple Mail refuses to keep a punycode
        # identity and submits MAIL FROM / From: with the Unicode domain.
        # Rewriting both (sender_canonical_classes defaults to
        # envelope_sender + header_sender) makes outgoing mail plain ASCII:
        # rspamd finds the A-label DKIM key, DMARC aligns, and postfix can
        # deliver to non-SMTPUTF8 receivers (it only *requires* SMTPUTF8 when
        # envelope or headers actually contain UTF-8).
        services.postfix = {
          mapFiles."sender_canonical" = pkgs.writeText "sender_canonical" (
            lib.concatStringsSep "\n" (
              lib.mapAttrsToList (ulabel: alabel: "@${ulabel} @${alabel}") facts.mail.unicode-domains
            )
          );
          settings.main = {
            sender_canonical_maps = "hash:/etc/postfix/sender_canonical";
            # Header rewriting only applies to clients matching this list;
            # the default (permit_inet_interfaces) excludes remote submission
            # clients, which would leave the UTF-8 From: header in place.
            local_header_rewrite_clients = [
              "permit_inet_interfaces"
              "permit_sasl_authenticated"
            ];
          };
        };

        # SNM's localDnsResolver (kresd, on by default) takes over
        # /etc/resolv.conf so rspamd can run DNSBL lookups through a private
        # recursive resolver (Spamhaus & co refuse shared/public resolvers).
        # kresd recurses from the roots, which breaks tailnet-internal names:
        # the homelab domain is split-horizon (NXDOMAIN publicly by design)
        # and the tailnet domain is MagicDNS. Stub both to tailscaled's
        # MagicDNS listener, which serves them regardless of who owns
        # resolv.conf.
        services.kresd.extraConfig = ''
          policy.add(policy.suffix(policy.STUB('100.100.100.100'), policy.todnames({'${facts.domain}', '${facts.wireguard.tailscale.tailnet}'})))
        '';

        # Retention: the archive on site-jp pulls every 30 minutes; anything
        # older than 30 days (and not flagged) is expunged from the hot server.
        systemd.services.mailserver-retention = {
          description = "Expunge mail older than 30 days (excluding flagged)";
          script = ''
            ${lib.getExe' config.services.dovecot2.package "doveadm"} \
              expunge -u delay@delay.email mailbox '*' savedbefore 30d not flagged
          '';
          serviceConfig = {
            Type = "oneshot";
            # "+" runs the hook as root: the Gatus token file is root-readable
            # only, and $SERVICE_RESULT covers every outcome.
            ExecStopPost = "+${
              mkReportResult "mailserver-retention-report-result" "cron" "Mail retention purge"
            }";
          };
          # Daily, UTC; the archive runs every 30 min, so mail is at most
          # 30 min un-archived when purged.
          startAt = "03:30";
        };

        # Outbound-SMTP (port 25) probe: Linode blocks egress on 25 until
        # support lifts the restriction, so this check stays red on Gatus and
        # turns green (with a resolved notification) the moment direct
        # delivery becomes possible. Full TCP + EHLO dialog with a real MX;
        # never sends mail. Also catches any future egress regression.
        systemd.services.mailserver-egress-probe = {
          description = "Probe outbound SMTP (port 25) reachability";
          script = ''
            ${lib.getExe pkgs.curl} -sS --connect-timeout 10 --max-time 20 \
              smtp://gmail-smtp-in.l.google.com:25 > /dev/null
          '';
          serviceConfig = {
            Type = "oneshot";
            # "+" runs the hook as root: the Gatus token file is root-readable
            # only, and $SERVICE_RESULT covers every outcome.
            ExecStopPost = "+${mkReportResult "mailserver-egress-probe-report-result" "mail" "Mail egress"}";
          };
          startAt = "*:20"; # hourly
        };
      };
    };
}
