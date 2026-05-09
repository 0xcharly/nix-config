{ self, ... }:
{
  flake.homeModules.profile-hardware-macbook = {
    imports = with self.homeModules; [
      devenv
      env
      fonts
      git
      home-manager-nixos
      keychain
      nixpkgs
      programs-atuin
      programs-coreutils
      programs-fish
      programs-jujutsu
      ssh
      terminals
      tmux
    ];

    node.keychain.autoLoadTrustedKeys = false;
  };
}
