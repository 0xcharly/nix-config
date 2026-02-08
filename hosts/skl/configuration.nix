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

    inputs.nix-config-colorscheme.modules.nixos.console

    inputs.nix-config-secrets.modules.nixos.blueprint
    inputs.nix-config-secrets.modules.nixos.nix-client-config
    inputs.nix-config-secrets.modules.nixos.services-tailscale
    inputs.nix-config-secrets.modules.nixos.users-delay

    flake.modules.common.nix-client-config
    flake.modules.common.nix-path
    flake.modules.common.nixpkgs-unfree
    flake.modules.common.nixpkgs-unstable
    flake.modules.common.overlays

    flake.modules.nixos.bootloader-systemd-boot
    flake.modules.nixos.essentials-desktop
    flake.modules.nixos.fs-zfs-system
    flake.modules.nixos.fs-zfs-zpool-root
    flake.modules.nixos.fs-zfs-zpool-root-home
    flake.modules.nixos.hardware-cpu-intel
    flake.modules.nixos.hardware-gpu-intel
    flake.modules.nixos.networking-bluetooth
    flake.modules.nixos.networking-wireless
    flake.modules.nixos.nix-client-config
    flake.modules.nixos.overlays
    flake.modules.nixos.programs-essentials
    flake.modules.nixos.programs-iotop
    flake.modules.nixos.programs-login-manager
    flake.modules.nixos.programs-packages-common
    flake.modules.nixos.programs-sudo
    flake.modules.nixos.programs-terminfo
    flake.modules.nixos.prometheus-exporters-node
    flake.modules.nixos.prometheus-exporters-zfs
    flake.modules.nixos.services-adb
    flake.modules.nixos.services-deploy-rs
    flake.modules.nixos.services-fail2ban
    flake.modules.nixos.services-openssh
    flake.modules.nixos.services-pipewire
    flake.modules.nixos.services-removable-devices
    flake.modules.nixos.services-tailscale
    flake.modules.nixos.system-common
    flake.modules.nixos.system-fonts
    flake.modules.nixos.users-delay
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
