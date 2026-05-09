{ flake, ... }:
{
  imports = with flake.homeModules; [
    devenv
    env
    git
    pkgs-essentials
    programs-atuin
    programs-fish
    programs-jujutsu
    ssh
    tmux
  ];
}
