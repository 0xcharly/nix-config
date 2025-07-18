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
  # The primary use case is to ensure when using ZFS that a pool isn’t imported
  # accidentally on a wrong machine.
  # https://search.nixos.org/options?channel=unstable&query=networking.hostId
  networking.hostId = config.modules.system.roles.nas.hostId;

  environment.systemPackages = with pkgs; [zfs];

  boot = {
    swraid.mdadmConf = ''
      MAILADDR root
    '';

    kernelModules = ["zfs"];
    supportedFilesystems = ["zfs" "btrfs"];

    # Enable mdadm for software RAID
    initrd = {
      supportedFilesystems = ["zfs" "btrfs"];
      availableKernelModules = ["raid1" "md_mod"];
      kernelModules = ["raid1"];
    };

    loader = {
      # Different systems may require a different one of the following two
      # options. The first instructs Grub to install itself in an EFI standard
      # location. And the second tells it to install somewhere custom, but
      # mutate the EFI NVRAM so EFI knows where to find it. The former
      # should work on any system. The latter allows you to share one ESP
      # among multiple OSes, but doesn't work on a few systems (namely
      # VirtualBox, which doesn't support persistent NVRAM).
      #
      # Just make sure to only have one of these enabled.
      grub.efiInstallAsRemovable = true;
      efi.canTouchEfiVariables = false;

      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
      };
    };
  };

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
      ExecStart = let
        mount-tank = pkgs.writeShellApplication {
          name = "mount-tank";
          runtimeInputs = with pkgs; [coreutils zfs];
          text = ''
            set -euo pipefail

            if ! zpool list tank >/dev/null 2>&1; then
              echo "Importing ZFS pool 'tank'…"
              zpool import tank
            else
              echo "ZFS pool 'tank' is already online."
            fi

            echo "Mounting ZFS datasets for /tank…"
            # NOTE: The following mounts all datasets in the pool, not only tank.
            # Reconsider this if we add more pools.
            zfs mount -a -l

            echo "Fixing permissions for /tank…"
            # Create the directories for the ZFS datasets, with the correct permissions.
            # TODO: Consider creating groups as well (eg. `backups`?).

            # Set root folder world-traversable.
            install -d --mode 751 --owner delay --group users /tank/backups
            install -d --mode 751 --owner ayako --group ayako /tank/backups/ayako
            install -d --mode 751 --owner delay --group delay /tank/backups/dad
            install -d --mode 751 --owner delay --group delay /tank/backups/delay
            install -d --mode 751 --owner delay --group users /tank/backups/services

            # Set root folder world-traversable.
            install -d --mode 751 --owner ayako --group users /tank/ayako
            install -d --mode 751 --owner ayako --group ayako /tank/ayako/files
            install -d --mode 751 --owner ayako --group users /tank/ayako/media

            # Set root folder world-traversable.
            install -d --mode 751 --owner delay --group users /tank/delay
            install -d --mode 771 --owner delay --group immich /tank/delay/album
            install -d --mode 751 --owner delay --group delay /tank/delay/beans
            install -d --mode 751 --owner delay --group delay /tank/delay/files
            install -d --mode 751 --owner delay --group jellyfin /tank/delay/media
            install -d --mode 751 --owner delay --group delay /tank/delay/notes
            install -d --mode 751 --owner delay --group delay /tank/delay/vault
          '';
        };
      in
        lib.getExe mount-tank;
    };
  };

  # NOTE: services-related group currently need to exist to set the proper
  # permissions on the secondaries. Would it be better to simply keep files
  # separate from backups? (i.e. /tank/delay and /tank/ayako only exist on the
  # primary?) Or should we just systematically create all users on all machines?
  # Seems like this would unnecessarily increase the attack surface…
  # TODO: figure out a better way to do this.
  users.groups.immich = {};
  users.groups.jellyfin = {};

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

      inherit (config.modules.system.roles.nas) drives;
    in {
      # System: these SSD are mirrored in RAID1.
      disk0 = raid1 drives.nvme0; # NVMe 1
      disk1 = raid1 drives.nvme1; # NVMe 2
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
              start = "-38G"; # Size of RAM + square root of RAM.
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
          mkAlbumDataset = mountpoint: {
            type = "zfs_fs";
            options = {
              mountpoint = "/tank/${mountpoint}";
              compression = "zstd"; # Better compression for text and PDFs.
              recordsize = "1M"; # Larger blocks improve performance for large sequential files.
              encryption = "aes-256-gcm";
              keyformat = "passphrase";
              keylocation = "file://${config.age.secrets."zfs/tank/${mountpoint}.key".path}";
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

          mkBackupDatasets = datasets: lib.mergeAttrsList (builtins.map mkBackupDataset datasets);
        in
          lib.mergeAttrsList [
            (namespace "backups" (mkBackupDatasets ["ayako" "dad" "delay" "services"]))

            (namespace "delay" {
              album = mkAlbumDataset "delay/album";
              beans = mkGenericDataset "delay/beans";
              files = mkGenericDataset "delay/files";
              media = mkMediaDataset "delay/media";
              notes = mkGenericDataset "delay/notes";
              vault = mkGenericDataset "delay/vault";
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
