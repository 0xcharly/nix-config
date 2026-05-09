{ self, ... }:
{
  flake.homeModules.profile-hardware-server = {
    imports = with self.homeModules; [
      environment
      environment-development
      home-manager-nixos
      nixpkgs
      programs-atuin
      programs-atuin-sync
      programs-coreutils
      programs-fish
      programs-tmux
      programs-vcs
      secrets
      ssh
    ];
  };
}
