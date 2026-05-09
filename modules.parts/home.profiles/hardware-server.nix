{ self, ... }:
{
  flake.homeModules.profile-hardware-server = {
    imports = with self.homeModules; [
      environment
      environment-dev
      git
      home-manager-nixos
      nixpkgs
      programs-atuin
      programs-atuin-sync
      programs-coreutils
      programs-fish
      programs-jujutsu
      programs-tmux
      secrets
      ssh
    ];
  };
}
