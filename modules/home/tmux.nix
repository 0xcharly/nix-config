{inputs, ...}: {pkgs, ...}: {
  imports = [inputs.nix-config-colorscheme.modules.home.tmux];

  programs.tmux = {
    enable = true;
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
    extraConfig = builtins.readFile ./tmux.conf;
  };
}
