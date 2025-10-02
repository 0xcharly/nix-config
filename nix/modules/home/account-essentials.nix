{flake, ...}: {
  imports = [
    flake.modules.home.atuin
    flake.modules.home.catppuccin
    flake.modules.home.env
    flake.modules.home.fish
    flake.modules.home.git
    flake.modules.home.jujutsu
    flake.modules.home.pkgs-essentials
    flake.modules.home.ssh
    flake.modules.home.tasks
    flake.modules.home.tmux
  ];
}
