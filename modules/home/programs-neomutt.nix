{ self, ... }:
{
  flake.homeModules.programs-neomutt =
    { osConfig, ... }:
    {
      imports = [ self.homeModules.programs-neomutt-common ];

      accounts.email.accounts.delay = {
        primary = true;
        address = "charly@delay.email";
        realName = "Charly Delay";
        userName = "delay@delay.email";
        # Plaintext credential shared with the site-jp mail-archive job;
        # dovecot/postfix SASL check the same account password.
        passwordCommand = "cat ${osConfig.age.secrets."mail-account/delay.passwd".path}";
        # Maildir at ~/Maildir/delay (HM defaults: maildirBasePath "Maildir",
        # maildir.path = account name).
        folders = {
          inbox = "INBOX";
          sent = "Sent"; # FCC to +Sent; mbsync pushes it to the server
          trash = "Deleted Messages";
        };
        imap.host = self.lib.facts.mail.fqdn; # dovecot IMAPS :993
        smtp = {
          host = self.lib.facts.mail.fqdn; # mx.delay.email -> smtps://…:465
          port = 465;
        };
        mbsync = {
          enable = true;
          create = "both"; # new local folders (e.g. Sent on first FCC) appear server-side
          expunge = "both"; # deletions propagate; the site-jp archive never sees them (pull-only)
          extraConfig.channel.CopyArrivalDate = "yes";
        };
        neomutt = {
          enable = true;
          extraMailboxes = [
            "Drafts"
            "Sent"
            "Junk"
            "Deleted Messages"
          ];
        };
      };

      # Quick-send aliases (`m todo<Tab>` / To: todo). NeoMutt is built with
      # libidn2 and idn_encode defaults on, so the UTF-8 domain is punycoded
      # (xn--7ck8cva5eb.com) on send.
      programs.neomutt.extraConfig = ''
        alias todo todo@チャーリー.com
      '';

      programs.mbsync.enable = true;
      services.mbsync.enable = true; # systemd user timer, every 5 min (HM default "*:0/5")
    };
}
