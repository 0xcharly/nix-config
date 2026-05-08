{
  flake,
  inputs,
  hostName,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")

    inputs.nix-config-colorscheme.nixosModules.console

    inputs.nix-config-secrets.nixosModules.default
    inputs.nix-config-secrets.nixosModules.jptax-fa5003-inputs
    inputs.nix-config-secrets.nixosModules.nix-client-config
    inputs.nix-config-secrets.nixosModules.services-tailscale
    inputs.nix-config-secrets.nixosModules.ssh-keys-ring-0-tier
    inputs.nix-config-secrets.nixosModules.users-delay

    flake.modules.generic.nix-client-config
    flake.modules.generic.nix-path

    flake.nixosModules.bootloader-systemd-boot
    flake.nixosModules.essentials-desktop
    flake.nixosModules.fs-zfs-system
    flake.nixosModules.fs-zfs-zpool-root
    flake.nixosModules.fs-zfs-zpool-root-home
    flake.nixosModules.hardware-cpu-amd
    flake.nixosModules.hardware-gpu-amd
    flake.nixosModules.hardware-wake-on-lan
    flake.nixosModules.hardware-zmk-studio
    flake.nixosModules.networking-common
    flake.nixosModules.networking-resolved
    flake.nixosModules.nix-build-aarch64
    flake.nixosModules.nix-client-config
    flake.nixosModules.nixpkgs-unfree
    flake.nixosModules.nixpkgs-unstable
    flake.nixosModules.programs-apdbctl
    flake.nixosModules.programs-essentials
    flake.nixosModules.programs-gnome-calendar
    flake.nixosModules.programs-greetd
    flake.nixosModules.programs-greetd-autologin
    flake.nixosModules.programs-iotop
    flake.nixosModules.programs-packages-common
    flake.nixosModules.programs-secrets
    flake.nixosModules.programs-steam
    flake.nixosModules.programs-sudo
    flake.nixosModules.programs-terminfo
    flake.nixosModules.prometheus-exporters-node
    flake.nixosModules.prometheus-exporters-zfs
    flake.nixosModules.services-adb
    flake.nixosModules.services-deploy-rs
    flake.nixosModules.services-fail2ban
    flake.nixosModules.services-ollama
    flake.nixosModules.services-openssh
    flake.nixosModules.services-pipewire
    flake.nixosModules.services-removable-devices
    flake.nixosModules.services-tailscale
    flake.nixosModules.system-common
    flake.nixosModules.system-fonts
    flake.nixosModules.users-delay
  ];

  # System config.
  node = {
    fs.zfs = {
      hostId = "0a52fab4";
      system = {
        disk = "/dev/disk/by-id/nvme-CT4000T700SSD3_2340E87BB2E0";
        luksPasswordFile = "/tmp/root-disk-encryption.key";
        swapSize = "72G"; # Size of RAM + square root of RAM for hibernate
      };
    };

    networking.wakeOnLan.interface = "enp115s0";
    users.delay.ssh.authorizeTailscaleInternalKey = true;
  };

  boot.initrd.availableKernelModules = [
    "ahci"
    "nvme"
    "sd_mod"
    "usbhid"
    "xhci_pci"
  ];

  networking = {
    inherit hostName;
    domain = "qyrnl.com";
    interfaces.enp115s0.useDHCP = true;
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "25.05";
}
