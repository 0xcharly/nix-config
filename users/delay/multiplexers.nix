{pkgs, ...}: let
in {
  home.packages = [
    pkgs.tmux-open-git-repository-fish
  ];

  programs.tmux = {
    enable = true;
    shell = pkgs.lib.getExe pkgs.fish;
    terminal = "xterm-ghostty";
    # terminal = "wezterm";
    aggressiveResize = true;
    escapeTime = 0;
    historyLimit = 100000;
    keyMode = "vi";
    mouse = true;
    sensibleOnTop = false;
    plugins = [
      {
        plugin = pkgs.tmuxPlugins.fingers;
        extraConfig = "set -g @plugin 'Morantron/tmux-fingers'";
      }
      {
        plugin = pkgs.tmuxPlugins.yank;
        extraConfig = "set -g @plugin 'tmux-plugins/tmux-yank'";
      }
    ];
    extraConfig = builtins.readFile ./tmux/tmux.conf;
  };
}
