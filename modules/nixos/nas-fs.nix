{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [inputs.disko.nixosModules.disko];
}
// lib.mkIf config.modules.system.roles.nas.enable {
  boot.swraid.mdadmConf = ''
    MAILADDR root
  '';

  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
  };

  # The primary use case is to ensure when using ZFS that a pool isn’t imported
  # accidentally on a wrong machine.
  # https://search.nixos.org/options?channel=24.11&query=networking.hostId
  networking.hostId = config.modules.system.roles.nas.hostId;

  environment.systemPackages = with pkgs; [zfs];

  boot.kernelModules = ["zfs"];
  boot.supportedFilesystems = ["zfs"];

  # Automatically mount the ZFS pool when agenix secrets are mounted.
  systemd.services.zfs-mount-tank = {
    description = "Mount ZFS pool `tank` and its datasets";

    # Wait for the agenix service to be running / complete before mounting the ZFS pool.
    after = ["run-agenix.d.mount" "zfs-import.target"];
    requires = ["run-agenix.d.mount" "zfs-import.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "mount-tank" ''
        set -euo pipefail

        if ! ${pkgs.zfs}/bin/zpool list tank >/dev/null 2>&1; then
          echo "Importing ZFS pool 'tank'…"
          ${pkgs.zfs}/bin/zpool import tank
        else
          echo "ZFS pool 'tank' is already online."
        fi

        echo "Mounting ZFS datasets for /tank…"
        # NOTE: the following mounts all datasets in the pool, not only tank.
        # Reconsider this if we add more pools.
        ${pkgs.zfs}/bin/zfs mount -a -l

        echo "Fixing permissions for /tank…"
        # Create the directories for the ZFS datasets, with the correct permissions.
        # TODO: Consider creating groups as well (eg. `backups`?).
        ${pkgs.coreutils}/bin/install -d --mode 750 --owner delay --group users /tank/backups
        ${pkgs.coreutils}/bin/install -d --mode 750 --owner delay --group users /tank/backups/ayako
        ${pkgs.coreutils}/bin/install -d --mode 750 --owner delay --group users /tank/backups/dad
        ${pkgs.coreutils}/bin/install -d --mode 750 --owner delay --group users /tank/backups/delay

        # TODO: Create the `ayako` user and update permissions.
        ${pkgs.coreutils}/bin/install -d --mode 750 --owner delay --group users /tank/ayako
        ${pkgs.coreutils}/bin/install -d --mode 750 --owner delay --group users /tank/ayako/files
        ${pkgs.coreutils}/bin/install -d --mode 750 --owner delay --group users /tank/ayako/media

        ${pkgs.coreutils}/bin/install -d --mode 750 --owner delay --group users /tank/delay
        ${pkgs.coreutils}/bin/install -d --mode 750 --owner delay --group users /tank/delay/beans
        ${pkgs.coreutils}/bin/install -d --mode 750 --owner delay --group users /tank/delay/files
        ${pkgs.coreutils}/bin/install -d --mode 750 --owner delay --group users /tank/delay/media
      '';
    };
  };

  disko.devices = {
    disk = let
      raid1 = device: {
        type = "disk";
        inherit device;
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02"; # Grub MBR
            };
            ESP = {
              type = "EF00"; # UEFI
              size = "500M";
              content = {
                type = "mdraid";
                name = "boot";
              };
            };
            mdadm = {
              size = "100%"; # Remainder of the disk.
              content = {
                type = "mdraid";
                name = "system";
              };
            };
          };
        };
      };
      zpool = device: {
        type = "disk";
        inherit device;
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
          };
        };
      };

      drives = config.modules.system.roles.nas.drives;
    in {
      # System: these SSD are mirrored in RAID1.
      disk0 = raid1 drives.nvme0; # Front NVMe
      disk1 = raid1 drives.nvme1; # Back NVMe
      # Backup: these HDD are set up in RAIDZ1.
      data0 = zpool drives.sata0; # SATA 1
      data1 = zpool drives.sata1; # SATA 2
      data2 = zpool drives.sata2; # SATA 3
      data3 = zpool drives.sata3; # SATA 4
    };
    mdadm = {
      boot = {
        type = "mdadm";
        level = 1;
        metadata = "1.0";
        content = {
          type = "filesystem";
          format = "vfat";
          mountpoint = "/boot";
          mountOptions = ["umask=0077"];
        };
      };
      system = {
        type = "mdadm";
        level = 1;
        content = {
          type = "gpt";
          partitions = {
            swap = {
              label = "swap";
              start = "-38G"; # Size of RAM + square root of RAM. Required for hibernation.
              content.type = "swap";
            };
            nixos = {
              label = "nixos";
              size = "100%"; # Remainder of the disk.
              content = {
                type = "btrfs";
                subvolumes = {
                  "NIXOS" = {};
                  "NIXOS/rootfs" = {
                    mountpoint = "/";
                    mountOptions = ["compress=zstd"];
                  };
                  "NIXOS/nix" = {
                    mountpoint = "/nix";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
                };
              };
            };
          };
        };
      };
    };
    zpool = {
      tank = {
        type = "zpool";
        mode = "raidz1";
        rootFsOptions = {
          compression = "zstd";
          "com.sun:auto-snapshot" = "true";
        };
        mountpoint = null;

        datasets = let
          namespace = dataset-name: sub-datasets:
            {
              ${dataset-name} = {
                type = "zfs_fs";
                options.mountpoint = "none";
              };
            }
            // (lib.attrsets.foldlAttrs (acc: sub-dataset-name: value: acc // {"${dataset-name}/${sub-dataset-name}" = value;}) {} sub-datasets);
          # A dataset for backups.
          mkBackupDataset = name: {
            ${name} = {
              type = "zfs_fs";
              options = {
                mountpoint = "/tank/backups/${name}";
                compression = "lz4"; # Fast and space-efficient.
                atime = "off"; # Disables updating access times.
                recordsize = "128K"; # Default block size.
                encryption = "aes-256-gcm";
                keyformat = "passphrase";
                keylocation = "file://${config.age.secrets."zfs/tank/backups/${name}.key".path}";
              };
            };
          };
          # A dataset for regular files. Better suited for small files.
          mkGenericDataset = mountpoint: {
            type = "zfs_fs";
            options = {
              mountpoint = "/tank/${mountpoint}";
              compression = "zstd"; # Better compression for text and PDFs.
              recordsize = "16K"; # Smaller blocks are better for small text files.
              encryption = "aes-256-gcm";
              keyformat = "passphrase";
              keylocation = "file://${config.age.secrets."zfs/tank/${mountpoint}.key".path}";
            };
          };
          # A dataset for media files. Better suited for large files.
          mkMediaDataset = mountpoint: {
            type = "zfs_fs";
            options = {
              mountpoint = "/tank/${mountpoint}";
              compression = "lz4"; # Fast and space-efficient.
              atime = "off"; # Disables updating access times.
              recordsize = "1M"; # Larger blocks improve performance for large sequential files.
              encryption = "aes-256-gcm";
              keyformat = "passphrase";
              keylocation = "file://${config.age.secrets."zfs/tank/${mountpoint}.key".path}";
            };
          };
        in
          lib.mergeAttrsList [
            (
              namespace "backups" (
                lib.mergeAttrsList (builtins.map mkBackupDataset ["ayako" "dad" "delay"])
              )
            )

            (namespace "delay" {
              beans = mkGenericDataset "delay/beans";
              files = mkGenericDataset "delay/files";
              media = mkMediaDataset "delay/media";
            })

            (namespace "ayako" {
              files = mkGenericDataset "ayako/files";
              media = mkMediaDataset "ayako/media";
            })
          ];
      };
    };
  };
}
