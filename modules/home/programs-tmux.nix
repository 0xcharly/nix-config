{ self, ... }:
{
  flake.homeModules.programs-tmux = {
    imports = [ self.homeModules.colors-tmux ];

    programs.tmux = {
      enable = true;
      aggressiveResize = true;
      escapeTime = 0;
      focusEvents = true;
      historyLimit = 100000;
      keyMode = "vi";
      mouse = true;
      sensibleOnTop = false;
      # tmux(1) requires default-terminal to be "screen*" or "tmux*"; anything
      # else (e.g. xterm-ghostty) makes programs inside tmux misdetect their
      # environment. Outer-terminal capabilities (truecolor, undercurl,
      # clipboard) are declared per client TERM in tmux.conf instead.
      terminal = "tmux-256color";
      extraConfig = builtins.readFile ./tmux/tmux.conf;
    };
  };
}
