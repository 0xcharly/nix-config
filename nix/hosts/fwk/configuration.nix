{
  flake,
  inputs,
  hostName,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")

    inputs.nix-config-secrets.modules.nixos.blueprint
    inputs.nix-config-secrets.modules.nixos.nix-client-config
    inputs.nix-config-secrets.modules.nixos.services-tailscale
    inputs.nix-config-secrets.modules.nixos.users-delay

    flake.modules.common.nix-client-config
    flake.modules.common.nix-path
    flake.modules.common.nixpkgs-unfree
    flake.modules.common.nixpkgs-unstable
    flake.modules.common.overlays

    flake.modules.nixos.fs-zfs-system
    flake.modules.nixos.hardware-cpu-amd
    flake.modules.nixos.hardware-framework-13
    flake.modules.nixos.hardware-laptop-essentials
    flake.modules.nixos.hardware-gpu-amd
    flake.modules.nixos.networking-bluetooth
    flake.modules.nixos.networking-wireless
    flake.modules.nixos.nix-client-config
    flake.modules.nixos.overlays
    flake.modules.nixos.programs-hyprland
    flake.modules.nixos.programs-iotop
    flake.modules.nixos.programs-packages-common
    flake.modules.nixos.programs-sudo
    flake.modules.nixos.programs-terminfo
    flake.modules.nixos.services-deploy-rs
    flake.modules.nixos.services-fail2ban
    flake.modules.nixos.services-openssh
    flake.modules.nixos.services-removable-devices
    flake.modules.nixos.services-tailscale
    flake.modules.nixos.system-common
    flake.modules.nixos.system-fonts
    flake.modules.nixos.users-delay
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

    networking.bluetooth.enableA2DPSink = true;

    users.delay.ssh.authorizeTailscaleInternalKey = true;
  };

  boot.initrd.availableKernelModules = [
    "ahci"
    "nvme"
    "sd_mod"
    "usbhid"
    "xhci_pci"
  ];

  services.logind = {
    lidSwitch = "hybrid-sleep";
    lidSwitchExternalPower = "suspend";
    powerKey = "suspend";
    powerKeyLongPress = "poweroff";
  };

  networking = {
    inherit hostName;
    interfaces.wlp192s0.useDHCP = true;
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "25.05";
}
