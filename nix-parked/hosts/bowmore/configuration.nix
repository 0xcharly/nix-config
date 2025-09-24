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
    inputs.nix-config-secrets.modules.nixos.disk-encryption-keys
    inputs.nix-config-secrets.modules.nixos.nix-client-config
    inputs.nix-config-secrets.modules.nixos.services-tailscale
    inputs.nix-config-secrets.modules.nixos.users-delay

    flake.modules.common.nix-client-config
    flake.modules.common.nix-path
    flake.modules.common.nixpkgs-unfree
    flake.modules.common.nixpkgs-unstable
    flake.modules.common.overlays

    flake.modules.nixos.fs-minisforum-n5-zfs-system
    flake.modules.nixos.fs-minisforum-n5-zfs-backup
    flake.modules.nixos.fs-zfs-mount-tank
    flake.modules.nixos.fs-zfs-replication
    # TODO: Enable on primary.
    # flake.modules.nixos.fs-zfs-snapshots
    flake.modules.nixos.hardware-cpu-amd
    flake.modules.nixos.hardware-gpu-intel
    flake.modules.nixos.initrd-unlock-over-ssh
    flake.modules.nixos.initrd-tailscale
    flake.modules.nixos.networking-common
    flake.modules.nixos.nix-client-config
    flake.modules.nixos.programs-iotop
    flake.modules.nixos.programs-packages-common
    flake.modules.nixos.programs-secrets
    flake.modules.nixos.programs-sudo
    flake.modules.nixos.programs-terminfo
    flake.modules.nixos.prometheus-exporters-node
    flake.modules.nixos.prometheus-exporters-zfs
    flake.modules.nixos.services-deploy-rs
    flake.modules.nixos.services-fail2ban
    flake.modules.nixos.services-openssh
    flake.modules.nixos.services-samba-ayako
    flake.modules.nixos.services-tailscale
    flake.modules.nixos.system-common
    flake.modules.nixos.users-ayako
    flake.modules.nixos.users-delay
  ];

  # System config.
  node = {
    boot.initrd.ssh-unlock.kernelModules = ["atlantic" "r8169"];

    fs.zfs = {
      hostId = "71fe60d5";
      system = {
        # System drives.
        disk0 = "/dev/disk/by-id/nvme-Samsung_SSD_980_500GB_S78GNL0XC30952W"; # NVMe Left.
        disk1 = "/dev/disk/by-id/nvme-Samsung_SSD_980_500GB_S78GNL0XC30991Y"; # NVMe Right.
        # TODO: Update disk ID.
        # swapDisk = "/dev/disk/by-id/nvme-AirDisk_128GB_SSD_QES481B001642P110N";
        # Encryption keys.
        luksPasswordFile = "/tmp/root-disk-encryption.key";
      };
      backup = {
        # Backup drives.
        disk0 = "/dev/disk/by-id/ata-ST24000NT002-3N1101_ZYD2E1FW";
        disk1 = "/dev/disk/by-id/ata-ST24000NT002-3N1101_ZYD20R4R";
        disk2 = "/dev/disk/by-id/ata-ST24000NT002-3N1101_ZYD254N6";
        disk3 = "/dev/disk/by-id/ata-ST24000NT002-3N1101_ZYD160A1";
        # TODO: Update disk ID.
        # disk4 = "/dev/disk/by-id/ata-ST24000NT002-3N1101_ZYD8JJ2R";
      };
      # snapshots = {
      #   lowFrequency = ["tank/backups"];
      #   highFrequency = ["tank/dataDirs"];
      # };
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
    interfaces.enp197s0.useDHCP = true;
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "25.05";
}
