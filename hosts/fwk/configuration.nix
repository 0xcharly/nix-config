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
    inputs.nix-config-secrets.nixosModules.ssh-keys-ring-0-tier
    inputs.nix-config-secrets.nixosModules.users-delay

    flake.nixosModules.bootloader-systemd-boot
    flake.nixosModules.essentials-laptop
    flake.nixosModules.fs-zfs-system
    flake.nixosModules.fs-zfs-zpool-root
    flake.nixosModules.fs-zfs-zpool-root-home
    flake.nixosModules.hardware-cpu-amd
    flake.nixosModules.hardware-framework-13
    flake.nixosModules.hardware-gpu-amd
    flake.nixosModules.hardware-zmk-studio
    flake.nixosModules.networking-bluetooth
    flake.nixosModules.networking-wireless
    flake.nixosModules.nix-build-aarch64
    flake.nixosModules.nix-config
    flake.nixosModules.nixpkgs-unfree
    flake.nixosModules.nixpkgs-unstable
    flake.nixosModules.programs-essentials
    flake.nixosModules.programs-gnome-calendar
    flake.nixosModules.programs-greetd
    flake.nixosModules.programs-greetd-autologin
    flake.nixosModules.programs-iotop
    flake.nixosModules.programs-packages-common
    flake.nixosModules.programs-secrets
    flake.nixosModules.programs-sudo
    flake.nixosModules.programs-terminfo
    flake.nixosModules.prometheus-exporters-node
    flake.nixosModules.prometheus-exporters-zfs
    flake.nixosModules.services-deploy-rs
    flake.nixosModules.services-fail2ban
    flake.nixosModules.services-openssh
    flake.nixosModules.services-removable-devices
    flake.nixosModules.services-tailscale
    flake.nixosModules.system-common
    flake.nixosModules.system-fonts
    flake.nixosModules.users-delay
  ];

  # System config.
  node = {
    fs.zfs = {
      hostId = "7375168d";
      system = {
        disk = "/dev/disk/by-id/nvme-WD_BLACK_SN850X_4000GB_251103801906";
        luksPasswordFile = "/tmp/root-disk-encryption.key";
        swapSize = "72G"; # Size of RAM + square root of RAM for hibernate.
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

  services.logind.settings.Login = {
    HandleLidSwitch = "hybrid-sleep";
    HandleLidSwitchExternalPower = "suspend";
    HandlePowerKey = "suspend";
    HandlePowerKeyLongPress = "poweroff";
  };

  networking = {
    inherit hostName;
    domain = "qyrnl.com";
    interfaces.wlp192s0.useDHCP = true;
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "25.05";
}
