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
    inputs.nix-config-secrets.modules.nixos.services-miniflux
    inputs.nix-config-secrets.modules.nixos.services-msmtp
    inputs.nix-config-secrets.modules.nixos.services-tailscale
    inputs.nix-config-secrets.modules.nixos.services-tailscale-initrd
    inputs.nix-config-secrets.modules.nixos.services-vaultwarden
    inputs.nix-config-secrets.modules.nixos.users-delay

    flake.modules.common.nix-client-config
    flake.modules.common.nix-path
    flake.modules.common.nixpkgs-unfree
    flake.modules.common.nixpkgs-unstable
    flake.modules.common.overlays

    flake.modules.nixos.bootloader-systemd-boot
    flake.modules.nixos.fs-zfs-backup-minisforum-n5
    flake.modules.nixos.fs-zfs-mount-tank
    flake.modules.nixos.fs-zfs-replication
    flake.modules.nixos.fs-zfs-system-minisforum-n5
    flake.modules.nixos.fs-zfs-zpool-root
    flake.modules.nixos.fs-zfs-zpool-root-data
    flake.modules.nixos.fs-zfs-zpool-root-data-postgresql
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
    flake.modules.nixos.selfhosted-atuin
    flake.modules.nixos.selfhosted-forgejo
    flake.modules.nixos.selfhosted-golink
    flake.modules.nixos.selfhosted-grafana
    flake.modules.nixos.selfhosted-immich
    flake.modules.nixos.selfhosted-jellyfin
    flake.modules.nixos.selfhosted-miniflux
    flake.modules.nixos.selfhosted-paperless
    flake.modules.nixos.selfhosted-prometheus
    flake.modules.nixos.selfhosted-vaultwarden
    flake.modules.nixos.services-deploy-rs
    flake.modules.nixos.services-fail2ban
    flake.modules.nixos.services-msmtp
    flake.modules.nixos.services-openssh
    # flake.modules.nixos.services-samba-ayako
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
      # System drives.
      system = {
        disk0 = {
          device = "/dev/disk/by-id/nvme-Samsung_SSD_980_500GB_S78GNL0XC30952W"; # NVMe Left.
          bootPartitionUuid = "19430f4e-7a29-4761-ba17-2aaf52148427";
        };
        disk1 = {
          device = "/dev/disk/by-id/nvme-Samsung_SSD_980_500GB_S78GNL0XC30991Y"; # NVMe Right.
          bootPartitionUuid = "16234e47-2eb8-42fa-b937-2dd737521ada";
        };
        swapDisk = "/dev/disk/by-id/nvme-AirDisk_128GB_SSD_QES481B001084P110N";
        luksPasswordFile = "/tmp/root-disk-encryption.key";
      };
      # Backup drives.
      backup = {
        disk0 = "/dev/disk/by-id/ata-ST24000NT002-3N1101_ZYD2E1FW";
        disk1 = "/dev/disk/by-id/ata-ST24000NT002-3N1101_ZYD20R4R";
        disk2 = "/dev/disk/by-id/ata-ST24000NT002-3N1101_ZYD254N6";
        disk3 = "/dev/disk/by-id/ata-ST24000NT002-3N1101_ZYD160A1";
        disk4 = "/dev/disk/by-id/ata-ST24000NT002-3N1101_WYD05N6H";
      };
      # snapshots = {
      #   lowFrequency = ["tank/backups"];
      #   highFrequency = ["tank/dataDirs"];
      # };
    };

    services = {
      atuin.enable = true;
      forgejo.enable = true;
      golink.enable = true;
      grafana.enable = true;
      immich.enable = true;
      jellyfin.enable = true;
      miniflux.enable = true;
      msmtp.enable = true;
      paperless.enable = true;
      prometheus.enable = true;
      vaultwarden.enable = true;
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
