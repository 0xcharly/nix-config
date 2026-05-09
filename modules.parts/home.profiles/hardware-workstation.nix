{ self, ... }:
{
  flake.homeModules.profile-hardware-workstation = {
    imports = with self.homeModules; [
      environment
      environment-desktop
      environment-desktop-wayland
      environment-development
      home-manager
      home-manager-age
      home-manager-nix
      install-fonts
      nixpkgs
      programs-atuin
      programs-atuin-sync
      programs-beeper
      programs-browsers
      programs-cachix
      programs-core-display
      programs-core-headless
      programs-file-managers
      programs-fish
      programs-opencode
      programs-password-managers
      programs-ssh
      programs-terminals
      programs-tmux
      programs-vcs
      programs-zathura
      services-pipewire
      services-usb-auto-mount
    ];
  };
}
