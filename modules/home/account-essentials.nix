{ flake, ... }:
{
  imports = with flake.homeModules; [
    atuin
    devenv
    env
    fish
    git
    jujutsu
    pkgs-essentials
    ssh
    tmux
  ];
}
