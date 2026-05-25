{ self, inputs, ... }:
{
  my.hosts.dalmore = {
    stateVersion = "25.05";

    nixosModule =
      { modulesPath, ... }:
      {
        imports = [
          "${modulesPath}/installer/scan/not-detected.nix"

          inputs.nix-config-secrets.nixosModules.default
          inputs.nix-config-secrets.nixosModules.disk-encryption-keys
          inputs.nix-config-secrets.nixosModules.services-tailscale
          inputs.nix-config-secrets.nixosModules.services-tailscale-initrd

          self.nixosModules.access-directory
          self.nixosModules.bootloader-systemd-boot
          self.nixosModules.fs-zfs-backup-minisforum-n5
          self.nixosModules.fs-zfs-common
          self.nixosModules.fs-zfs-mount-tank
          self.nixosModules.fs-zfs-replication-replica
          self.nixosModules.fs-zfs-system-minisforum-n5
          self.nixosModules.fs-zfs-zpool-root
          self.nixosModules.fs-zfs-zpool-root-data
          self.nixosModules.hardware-cpu-amd
          self.nixosModules.initrd-tailscale
          self.nixosModules.initrd-unlock-over-ssh
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
          self.nixosModules.services-deploy-rs
          self.nixosModules.services-fail2ban
          self.nixosModules.services-openssh
          self.nixosModules.services-tailscale
          self.nixosModules.system-common
        ];

        # System config.
        node = {
          boot.initrd.ssh-unlock = {
            kernelModules = [
              "atlantic"
              "r8169"
            ];
            kernelParams = [ "ip=192.168.1.231::192.168.1.1:255.255.255.0:dalmore-initrd:enp197s0:off" ];
          };

          fs.zfs = {
            hostId = "eb3cd4cb";
            system = {
              # System drives
              disk0 = {
                device = "/dev/disk/by-id/nvme-Samsung_SSD_980_500GB_S78GNL0Y827740P"; # NVMe Left
                bootPartitionUuid = "5709a552-1e89-43fd-9e6a-205f3246dc76";
              };
              disk1 = {
                device = "/dev/disk/by-id/nvme-Samsung_SSD_980_500GB_S78GNL0Y827727J"; # NVMe Right
                bootPartitionUuid = "7260144b-b3c2-4b71-b91e-d874ef59ae01";
              };
              swapDisk = "/dev/disk/by-id/nvme-AirDisk_128GB_SSD_QES481B001642P110N";
              # Encryption keys
              luksPasswordFile = "/tmp/root-disk-encryption.key";
            };
            backup = {
              # Backup drives
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
      };

    users.delay.imports = [ self.homeModules.profile-hardware-server ];
  };
}
