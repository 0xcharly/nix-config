{ self, ... }:
{
  flake.homeModules.profile-hardware-macbook = {
    imports = with self.homeModules; [
      environment
      environment-development
      home-manager-nixos
      install-fonts
      nixpkgs
      programs-atuin
      programs-coreutils
      programs-fish
      programs-keychain
      programs-ssh
      programs-terminals
      programs-tmux
      programs-vcs
    ];
  };
}
