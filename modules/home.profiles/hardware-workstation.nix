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
      programs-antigravity
      programs-atuin-sync
      programs-beans
      programs-beeper
      programs-browsers
      programs-cachix
      programs-core-display
      programs-core-headless
      programs-cursor
      programs-file-managers
      programs-fish
      programs-hunk
      programs-keychain
      programs-llm-agents
      programs-nvim
      programs-password-managers
      programs-ssh
      programs-terminals
      programs-tmux
      programs-vcs
      programs-zathura
      services-nix-index
      services-pipewire
      services-usb-auto-mount
    ];

    config.node.wayland.arcshell.modules.powerProfile = true;
  };
}
