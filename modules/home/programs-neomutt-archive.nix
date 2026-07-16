{ self, ... }:
{
  flake.homeModules.programs-neomutt-archive =
    { osConfig, ... }:
    {
      imports = [ self.homeModules.programs-neomutt-common ];

      accounts.email = {
        maildirBasePath = "/tank/delay";
        accounts.delay = {
          primary = true;
          address = "charly@delay.email";
          realName = "Charly Delay";
          userName = "delay@delay.email";
          # Same plaintext credential the mail-archive mbsync job uses
          # (owner delay, mode 0400); dovecot/postfix SASL check the same
          # account password.
          passwordCommand = "cat ${osConfig.age.secrets."mail-account/delay.passwd".path}";
          maildir.path = "email"; # absPath = /tank/delay/email (default would be the account name)
          folders = {
            inbox = "INBOX";
            # No local FCC (record stays unset): nothing is ever written into
            # the pull-only mirror. Sent copies are FCC'd by the workstation
            # client into the server's Sent folder and mirrored here by the
            # mail-archive job like every other mailbox. An incidental send
            # from the archive saves no local copy, by design.
            sent = null;
            trash = "Deleted Messages";
          };
          # Never used for mail access (neomutt.mailboxType defaults to
          # "maildir"), but the HM neomutt module unconditionally evaluates
          # imap.tls.* when rendering ssl_force_tls — a null imap crashes
          # eval. The host is truthful regardless (dovecot IMAPS).
          imap.host = self.lib.facts.mail.fqdn;
          smtp = {
            host = self.lib.facts.mail.fqdn; # mx.delay.email -> smtps://…:465
            port = 465;
          };
          neomutt = {
            enable = true;
            extraMailboxes = [
              "Drafts"
              "Sent"
              "Junk"
              "Deleted Messages"
            ];
            extraConfig = ''
              # The archive Maildir is a pull-only mirror; keep neomutt's
              # writable state out of it.
              set postponed = "~/.local/state/neomutt/postponed"
            '';
          };
        };
      };

      # Pull-only mirror of the mailserver: open everything read-only so
      # nothing can be deleted by accident (deletions on the server are
      # never propagated here either — see services-mail-archive.nix).
      programs.neomutt.settings.read_only = "yes";
    };
}
