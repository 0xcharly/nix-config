{ self, inputs, ... }:
{
  my.hosts.site-jp = {
    stateVersion = "25.05";

    nixosModule =
      { modulesPath, config, ... }:
      {
        imports = [
          "${modulesPath}/installer/scan/not-detected.nix"

          inputs.nix-config-secrets.nixosModules.default
          inputs.nix-config-secrets.nixosModules.disk-encryption-keys
          inputs.nix-config-secrets.nixosModules.services-forgejo-ssh-host-keys
          inputs.nix-config-secrets.nixosModules.services-github-backup
          inputs.nix-config-secrets.nixosModules.services-hoopsnake-site-jp
          inputs.nix-config-secrets.nixosModules.services-linkwarden
          inputs.nix-config-secrets.nixosModules.services-miniflux
          inputs.nix-config-secrets.nixosModules.services-msmtp
          inputs.nix-config-secrets.nixosModules.services-radicale
          inputs.nix-config-secrets.nixosModules.services-tailscale
          inputs.nix-config-secrets.nixosModules.services-vaultwarden
          inputs.nix-config-secrets.nixosModules.zfs-replication-keys

          self.nixosModules.profile-hardware-server

          self.nixosModules.access-directory
          self.nixosModules.bootloader-systemd-boot
          self.nixosModules.fs-zfs-backup-minisforum-n5
          self.nixosModules.fs-zfs-common
          self.nixosModules.fs-zfs-mount-tank
          self.nixosModules.fs-zfs-replication-primary
          self.nixosModules.fs-zfs-system-minisforum-n5
          self.nixosModules.fs-zfs-zpool-root
          self.nixosModules.fs-zfs-zpool-root-data
          self.nixosModules.fs-zfs-zpool-root-data-postgresql
          # TODO: Enable on primary
          # self.nixosModules.fs-zfs-snapshots
          self.nixosModules.hardware-cpu-amd
          self.nixosModules.hardware-gpu-intel
          self.nixosModules.initrd-hoopsnake
          self.nixosModules.networking-common
          self.nixosModules.nix
          self.nixosModules.nixpkgs
          self.nixosModules.programs-essentials
          self.nixosModules.programs-iotop
          self.nixosModules.programs-packages-common
          self.nixosModules.programs-sudo
          self.nixosModules.programs-terminfo
          self.nixosModules.prometheus-exporters-node
          self.nixosModules.prometheus-exporters-zfs
          self.nixosModules.selfhosted-atuin
          self.nixosModules.selfhosted-cgit
          self.nixosModules.selfhosted-forgejo
          self.nixosModules.selfhosted-golink
          self.nixosModules.selfhosted-grafana
          self.nixosModules.selfhosted-immich
          self.nixosModules.selfhosted-jellyfin
          self.nixosModules.selfhosted-linkwarden
          self.nixosModules.selfhosted-miniflux
          self.nixosModules.selfhosted-navidrome
          self.nixosModules.selfhosted-paperless
          self.nixosModules.selfhosted-prometheus
          self.nixosModules.selfhosted-prometheus-tailscalesd
          self.nixosModules.selfhosted-radicale
          self.nixosModules.selfhosted-vaultwarden
          self.nixosModules.services-fail2ban
          self.nixosModules.services-github-backup
          self.nixosModules.services-msmtp
          self.nixosModules.services-openssh
          # self.nixosModules.services-samba-ayako
          self.nixosModules.services-tailscale
          self.nixosModules.system-common
          self.nixosModules.zfs-send-wrappers
        ];

        # System config
        node = {
          boot.initrd.hoopsnake.kernelModules = [
            "atlantic"
            "r8169"
          ];

          fs.zfs = {
            hostId = "71fe60d5";
            # System drives
            system = {
              disk0 = {
                device = "/dev/disk/by-id/nvme-Samsung_SSD_980_500GB_S78GNL0XC30952W"; # NVMe Left
                bootPartitionUuid = "19430f4e-7a29-4761-ba17-2aaf52148427";
              };
              disk1 = {
                device = "/dev/disk/by-id/nvme-Samsung_SSD_980_500GB_S78GNL0XC30991Y"; # NVMe Right
                bootPartitionUuid = "16234e47-2eb8-42fa-b937-2dd737521ada";
              };
              swapDisk = "/dev/disk/by-id/nvme-AirDisk_128GB_SSD_QES481B001084P110N";
              luksPasswordFile = "/tmp/root-disk-encryption.key";
            };
            # Backup drives
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

          networking.tailscale.enableSsh = true;

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

        networking.interfaces.enp197s0.useDHCP = true;
      };

    users.delay.imports = [ self.homeModules.profile-hardware-server ];
  };
}
