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

    inputs.nix-config-secrets.nixosModules.default
    inputs.nix-config-secrets.nixosModules.disk-encryption-keys
    inputs.nix-config-secrets.nixosModules.nix-client-config
    inputs.nix-config-secrets.nixosModules.services-tailscale
    inputs.nix-config-secrets.nixosModules.services-tailscale-initrd

    flake.modules.common.nix-client-config
    flake.modules.common.nix-path
    flake.modules.common.nixpkgs-unfree
    flake.modules.common.nixpkgs-unstable
    flake.modules.common.overlays

    flake.nixosModules.access-directory
    flake.nixosModules.bootloader-systemd-boot
    flake.nixosModules.fs-zfs-backup-minisforum-n5
    flake.nixosModules.fs-zfs-mount-tank
    flake.nixosModules.fs-zfs-replication-replica
    flake.nixosModules.fs-zfs-system-minisforum-n5
    flake.nixosModules.fs-zfs-zpool-root
    flake.nixosModules.fs-zfs-zpool-root-data
    flake.nixosModules.hardware-cpu-amd
    flake.nixosModules.initrd-unlock-over-ssh
    flake.nixosModules.initrd-tailscale
    flake.nixosModules.networking-common
    flake.nixosModules.nix-client-config
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
  ];

  # System config.
  node = {
    boot.initrd.ssh-unlock = {
      kernelModules = [
        "atlantic"
        "r8169"
      ];
      kernelParams = [ "ip=192.168.1.231::192.168.1.1:255.255.255.0:${hostName}-initrd:enp197s0:off" ];
    };

    fs.zfs = {
      hostId = "eb3cd4cb";
      system = {
        # System drives.
        disk0 = {
          device = "/dev/disk/by-id/nvme-Samsung_SSD_980_500GB_S78GNL0Y827740P"; # NVMe Left.
          bootPartitionUuid = "5709a552-1e89-43fd-9e6a-205f3246dc76";
        };
        disk1 = {
          device = "/dev/disk/by-id/nvme-Samsung_SSD_980_500GB_S78GNL0Y827727J"; # NVMe Right.
          bootPartitionUuid = "7260144b-b3c2-4b71-b91e-d874ef59ae01";
        };
        swapDisk = "/dev/disk/by-id/nvme-AirDisk_128GB_SSD_QES481B001642P110N";
        # Encryption keys.
        luksPasswordFile = "/tmp/root-disk-encryption.key";
      };
      backup = {
        # Backup drives.
        disk0 = "/dev/disk/by-id/ata-ST24000NT002-3N1101_WYD09GCG";
        disk1 = "/dev/disk/by-id/ata-ST24000NT002-3N1101_ZYD8GMWE";
        disk2 = "/dev/disk/by-id/ata-ST24000NT002-3N1101_ZYD8GTZ2";
        disk3 = "/dev/disk/by-id/ata-ST24000NT002-3N1101_ZYD8GZ5P";
        disk4 = "/dev/disk/by-id/ata-ST24000NT002-3N1101_ZYD8JJ2R";
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
    interfaces.enp197s0.ipv4.addresses = [
      {
        address = "192.168.1.232";
        prefixLength = 24;
      }
    ];
    defaultGateway = "192.168.1.1";
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "25.05";
}
