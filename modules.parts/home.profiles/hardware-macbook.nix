{ self, ... }:
{
  flake.homeModules.profile-hardware-macbook = {
    imports = with self.homeModules; [
      environment
      environment-development
      fonts
      home-manager-nixos
      keychain
      nixpkgs
      programs-atuin
      programs-coreutils
      programs-fish
      programs-terminals
      programs-tmux
      programs-vcs
      ssh
    ];

    node.keychain.autoLoadTrustedKeys = false;
  };
}
