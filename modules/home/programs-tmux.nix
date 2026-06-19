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
      extraConfig = builtins.readFile ./tmux/tmux.conf;
    };
  };
}
