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
    inputs.nix-config-secrets.nixosModules.services-tailscale-initrd
    inputs.nix-config-secrets.nixosModules.users-delay

    flake.nixosModules.bootloader-systemd-boot
    flake.nixosModules.fs-zfs-system
    flake.nixosModules.fs-zfs-zpool-root
    flake.nixosModules.fs-zfs-zpool-root-data
    flake.nixosModules.fs-zfs-zpool-root-home
    flake.nixosModules.hardware-cpu-intel
    flake.nixosModules.hardware-gpu-intel
    flake.nixosModules.initrd-tailscale
    flake.nixosModules.initrd-unlock-over-ssh
    flake.nixosModules.nix-build-aarch64
    flake.nixosModules.nix-config
    flake.nixosModules.nixpkgs-unfree
    flake.nixosModules.nixpkgs-unstable
    flake.nixosModules.programs-essentials
    flake.nixosModules.programs-iotop
    flake.nixosModules.programs-packages-common
    flake.nixosModules.programs-sudo
    flake.nixosModules.programs-terminfo
    flake.nixosModules.prometheus-exporters-node
    flake.nixosModules.prometheus-exporters-zfs
    flake.nixosModules.services-deploy-rs
    flake.nixosModules.services-fail2ban
    flake.nixosModules.services-openssh
    flake.nixosModules.services-tailscale
    flake.nixosModules.system-common
    flake.nixosModules.users-delay
  ];

  # System config.
  node = {
    boot.initrd.ssh-unlock.kernelModules = [ "r8169" ];

    fs.zfs = {
      hostId = "be2d9ac1";
      system = {
        disk = "/dev/disk/by-id/nvme-KINGSTON_OM8TAP41024K1-A00_50026B7383D8FFFF";
        luksPasswordFile = "/tmp/root-disk-encryption.key";
        swapSize = "16G";
      };
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
    interfaces = {
      enp195s0.useDHCP = true;
      enp196s0.useDHCP = true;
    };
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "25.11";
}
