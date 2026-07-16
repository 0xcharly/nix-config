{ self, ... }:
{
  flake.homeModules.programs-neomutt-common =
    { pkgs, lib, ... }:
    {
      imports = [ self.homeModules.colors-neomutt ];

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
        # vimKeys = true;
        sort = "reverse-threads"; # newest thread first
        sidebar = {
          enable = true;
          width = 28;
        };
        checkStatsInterval = 60; # unread counts in the sidebar
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
