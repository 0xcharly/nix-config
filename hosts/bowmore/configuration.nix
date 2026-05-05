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
    inputs.nix-config-secrets.nixosModules.services-forgejo-ssh-host-keys
    inputs.nix-config-secrets.nixosModules.services-github-backup
    inputs.nix-config-secrets.nixosModules.services-linkwarden
    inputs.nix-config-secrets.nixosModules.services-miniflux
    inputs.nix-config-secrets.nixosModules.services-msmtp
    inputs.nix-config-secrets.nixosModules.services-radicale
    inputs.nix-config-secrets.nixosModules.services-tailscale
    inputs.nix-config-secrets.nixosModules.services-tailscale-initrd
    inputs.nix-config-secrets.nixosModules.services-vaultwarden
    inputs.nix-config-secrets.nixosModules.zfs-replication-keys

    flake.modules.common.nix-client-config
    flake.modules.common.nix-path
    flake.modules.common.nixpkgs-unfree
    flake.modules.common.nixpkgs-unstable
    flake.modules.common.overlays

    flake.nixosModules.access-directory
    flake.nixosModules.bootloader-systemd-boot
    flake.nixosModules.fs-zfs-backup-minisforum-n5
    flake.nixosModules.fs-zfs-mount-tank
    flake.nixosModules.fs-zfs-replication-primary
    flake.nixosModules.fs-zfs-system-minisforum-n5
    flake.nixosModules.fs-zfs-zpool-root
    flake.nixosModules.fs-zfs-zpool-root-data
    flake.nixosModules.fs-zfs-zpool-root-data-postgresql
    # TODO: Enable on primary.
    # flake.nixosModules.fs-zfs-snapshots
    flake.nixosModules.hardware-cpu-amd
    flake.nixosModules.hardware-gpu-intel
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
    flake.nixosModules.selfhosted-atuin
    flake.nixosModules.selfhosted-cgit
    flake.nixosModules.selfhosted-forgejo
    flake.nixosModules.selfhosted-golink
    flake.nixosModules.selfhosted-grafana
    flake.nixosModules.selfhosted-immich
    flake.nixosModules.selfhosted-jellyfin
    flake.nixosModules.selfhosted-linkwarden
    flake.nixosModules.selfhosted-miniflux
    flake.nixosModules.selfhosted-navidrome
    flake.nixosModules.selfhosted-paperless
    flake.nixosModules.selfhosted-prometheus
    flake.nixosModules.selfhosted-prometheus-tailscalesd
    flake.nixosModules.selfhosted-radicale
    flake.nixosModules.selfhosted-vaultwarden
    flake.nixosModules.services-deploy-rs
    flake.nixosModules.services-fail2ban
    flake.nixosModules.services-github-backup
    flake.nixosModules.services-msmtp
    flake.nixosModules.services-openssh
    # flake.nixosModules.services-samba-ayako
    flake.nixosModules.services-tailscale
    flake.nixosModules.system-common
    flake.nixosModules.zfs-send-wrappers
  ];

  # System config.
  node = {
    boot.initrd.ssh-unlock.kernelModules = [
      "atlantic"
      "r8169"
    ];

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
      #   hourly = [
      #     "tank/delay/beans"
      #   ];
      #   daily = [
      #     "tank/ayako/files"
      #     "tank/ayako/media"
      #     "tank/backups/ayako"
      #     "tank/backups/dad"
      #     "tank/backups/delay"
      #     "tank/backups/github"
      #     "tank/backups/homelab"
      #     "tank/delay/album"
      #     "tank/delay/files"
      #     "tank/delay/forge/data"
      #     "tank/delay/forge/repo"
      #     "tank/delay/media"
      #     "tank/delay/music"
      #     "tank/delay/notes"
      #     "tank/delay/vault"
      #   ];
      # };
    };

    services = {
      atuin.enable = true;
      cgit.enable = true;
      forgejo.enable = true;
      golink.enable = true;
      grafana.enable = true;
      immich.enable = true;
      jellyfin.enable = true;
      linkwarden.enable = true;
      miniflux.enable = true;
      msmtp.enable = true;
      navidrome.enable = true;
      paperless.enable = true;
      prometheus = {
        enable = true;
        tailscalesd.enable = true;
      };
      radicale.enable = true;
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
