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
      pkgs-desktop-gui
      programs-atuin
      programs-atuin-sync
      programs-browsers
      programs-cachix
      programs-core-display
      programs-core-headless
      programs-fish
      programs-opencode
      programs-ssh
      programs-terminals
      programs-tmux
      programs-vcs
      services-pipewire
      services-usb-auto-mount
    ];
  };
}
