{ self, ... }:
{
  flake.homeModules.profile-hardware-server = {
    imports = with self.homeModules; [
      environment
      environment-development
      home-manager
      home-manager-age
      home-manager-nix
      nixpkgs
      programs-atuin
      programs-atuin-sync
      programs-core-headless
      programs-fish
      programs-nvim
      programs-ssh
      programs-tmux
      programs-vcs
    ];
  };
}
