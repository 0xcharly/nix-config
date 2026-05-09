{ self, ... }:
{
  flake.homeModules.profile-hardware-macbook = {
    imports = with self.homeModules; [
      environment
      environment-dev
      fonts
      git
      home-manager-nixos
      keychain
      nixpkgs
      programs-atuin
      programs-coreutils
      programs-fish
      programs-jujutsu
      programs-terminals
      programs-tmux
      ssh
    ];

    node.keychain.autoLoadTrustedKeys = false;
  };
}
