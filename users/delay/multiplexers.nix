{pkgs, ...}: let
in {
  home.packages = [
    pkgs.tmux-open-git-repository-fish
  ];

  programs.tmux = {
    enable = true;
    shell = pkgs.lib.getExe pkgs.fish;
    terminal = "xterm-ghostty";
    aggressiveResize = true;
    escapeTime = 0;
    historyLimit = 100000;
    keyMode = "vi";
    mouse = true;
    sensibleOnTop = false;
    extraConfig = builtins.readFile ./tmux.conf;
  };
}
