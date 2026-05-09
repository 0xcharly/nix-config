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
    inputs.nix-config-secrets.nixosModules.services-tailscale
    inputs.nix-config-secrets.nixosModules.users-delay

    flake.nixosModules.bootloader-systemd-boot
    flake.nixosModules.essentials-desktop
    flake.nixosModules.fs-zfs-system
    flake.nixosModules.fs-zfs-zpool-root
    flake.nixosModules.fs-zfs-zpool-root-home
    flake.nixosModules.hardware-cpu-intel
    flake.nixosModules.hardware-gpu-intel
    flake.nixosModules.networking-bluetooth
    flake.nixosModules.networking-wireless
    flake.nixosModules.nix-config
    flake.nixosModules.nixpkgs-unfree
    flake.nixosModules.nixpkgs-unstable
    flake.nixosModules.programs-essentials
    flake.nixosModules.programs-greetd
    flake.nixosModules.programs-greetd-autologin
    flake.nixosModules.programs-iotop
    flake.nixosModules.programs-packages-common
    flake.nixosModules.programs-secrets
    flake.nixosModules.programs-sudo
    flake.nixosModules.programs-terminfo
    flake.nixosModules.prometheus-exporters-node
    flake.nixosModules.prometheus-exporters-zfs
    flake.nixosModules.services-adb
    flake.nixosModules.services-deploy-rs
    flake.nixosModules.services-fail2ban
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
      hostId = "be2d9ac1";
      system = {
        disk = "/dev/disk/by-id/nvme-Samsung_SSD_950_PRO_512GB_S2GMNCAGB32083T";
        luksPasswordFile = "/tmp/root-disk-encryption.key";
        swapSize = "20G"; # Size of RAM + square root of RAM for hibernate
      };
    };

    networking = {
      bluetooth = {
        powerOnBoot = true;
        enableFastConnectable = true;
      };
      tailscale.acceptRoutes = true;
    };

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
    interfaces = {
      eno1.useDHCP = true;
      wlp3s0.useDHCP = true;
    };
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "25.05";
}
