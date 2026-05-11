{ self, ... }:
{
  flake.homeModules.profile-hardware-macbook = {
    imports = with self.homeModules; [
      environment
      environment-development
      home-manager
      home-manager-nix
      install-fonts
      nixpkgs
      programs-atuin
      programs-core-headless
      programs-fish
      programs-keychain
      programs-nvim
      programs-ssh
      programs-terminals
      programs-tmux
      programs-vcs
    ];
  };
}
