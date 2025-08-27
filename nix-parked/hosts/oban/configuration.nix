{
  flake,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")

    flake.modules.common.nix-client-config
    flake.modules.common.nix-path
    flake.modules.common.nixpkgs-unfree
    flake.modules.common.nixpkgs-unstable
    flake.modules.common.overlays

    flake.modules.nixos.fs-btrfs-system
    flake.modules.nixos.hardware-cpu-intel
    flake.modules.nixos.hardware-gpu-intel
    flake.modules.nixos.networking-common
    flake.modules.nixos.nix-client-config
    flake.modules.nixos.prometheus-exporters-node
    flake.modules.nixos.services-deploy-rs
    flake.modules.nixos.programs-packages-common
    flake.modules.nixos.programs-fail2ban
    flake.modules.nixos.programs-iotop

    flake.modules.home.atuin
    flake.modules.home.catppuccin
    flake.modules.home.fish
    flake.modules.home.fonts
    flake.modules.home.git
    flake.modules.home.jujutsu
    flake.modules.home.jujutsu-deprecated
    flake.modules.home.keychain
    flake.modules.home.pkgs-essentials
    flake.modules.home.tmux

    # TODO: complete.
  ];

  boot.initrd.availableKernelModules = [
    "ahci"
    "nvme"
    "sd_mod"
    "usbhid"
    "xhci_pci"
  ];

  # Network config.
  networking.interfaces.eno1.useDHCP = true;

  nixpkgs.hostPlatform = "x86_64-linux";

  # See comment in modules/nixos/module.nix.
  system.stateVersion = "25.05";
}
