{ self, ... }:
{
  flake.homeModules.programs-neomutt =
    {
      osConfig,
      pkgs,
      lib,
      ...
    }:
    {
      imports = [ self.homeModules.colors-neomutt ];

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
          passwordCommand = "cat ${osConfig.age.secrets."services/mail-archive/delay.passwd".path}";
          maildir.path = "email"; # absPath = /tank/delay/email (default would be the account name)
          folders = {
            inbox = "INBOX";
            # No local FCC: sent copies come back via the self-Bcc below
            # (record stays unset -> nothing is written into the mirror).
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

              # Sent-copy policy: Bcc yourself. The message loops through the
              # mailserver (catch-all alias) into INBOX and gets archived by
              # mbsync like any inbound mail. write_bcc defaults to no, so the
              # header is never disclosed to recipients (envelope-only).
              my_hdr Bcc: delay@delay.email
            '';
          };
        };
      };

      programs.neomutt = {
        enable = true;
        # NeoMutt only accepts #RRGGBB colours when ncurses reports 16M
        # colours (the COLORS gate in color/commands.c), which requires the
        # `RGB` terminfo capability. None of the terminfo entries in our
        # chain advertise it — kitty/ghostty/tmux only set the tmux-private
        # `Tc`, which ncurses ignores — so force xterm-direct: every
        # terminal reaching this host speaks truecolor. COLORTERM benefits
        # the spawned $editor (nvim).
        package = pkgs.symlinkJoin {
          name = "neomutt-directcolor";
          paths = [ pkgs.neomutt ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/neomutt \
              --set TERM xterm-direct \
              --set COLORTERM truecolor
          '';
        };
        editor = "nvim";
        vimKeys = true;
        sort = "reverse-threads"; # newest thread first
        sidebar = {
          enable = true;
          width = 28;
        };
        checkStatsInterval = 60; # unread counts in the sidebar
        settings = {
          # Pull-only mirror of the mailserver: open everything read-only so
          # nothing can be deleted by accident (deletions on the server are
          # never propagated here either — see services-mail-archive.nix).
          read_only = "yes";
        };
        extraConfig = ''
          # Render HTML-only mail inline.
          set mailcap_path = ${pkgs.writeText "mailcap" ''
            text/html; ${lib.getExe pkgs.w3m} -dump -I %{charset} -O utf-8 -T text/html %s; copiousoutput
          ''}
          auto_view text/html
        '';
      };
    };
}
