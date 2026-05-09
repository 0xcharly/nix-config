{ self, ... }:
{
  flake.homeModules.profile-hardware-macbook = {
    imports = with self.homeModules; [
      environment
      environment-development
      fonts
      home-manager-nixos
      nixpkgs
      programs-atuin
      programs-coreutils
      programs-fish
      programs-keychain
      programs-terminals
      programs-tmux
      programs-vcs
      ssh
    ];
  };
}
