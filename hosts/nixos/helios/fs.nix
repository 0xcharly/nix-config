{
  inputs,
  lib,
  config,
  ...
}: {
  imports = [inputs.disko.nixosModules.disko];

  disko.devices = {
    disk = let
      raid1 = device: {
        type = "disk";
        inherit device;
        content = {
          type = "gpt";
          partitions = {
            BOOT = {
              size = "1M";
              type = "EF02"; # for grub MBR
            };
            ESP = {
              start = "1M";
              end = "512M";
              type = "EF00"; # UEFI
              # type = "EF02"; # Grub MBR
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
    in {
      # These disks is mirrored in RAID1.
      disk0 = raid1 "/dev/nvme0n1p1";
      disk1 = raid1 "/dev/nvme1n1p1";
      data0 = zpool "/dev/sda";
      data1 = zpool "/dev/sdb";
      data2 = zpool "/dev/sdc";
      data3 = zpool "/dev/sdd";
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
              priority = 2;
              label = "swap";
              start = "-38G"; # Size of RAM + square root of RAM. Required for hibernation.
              content.type = "swap";
            };
            nixos = {
              priority = 3;
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
          backup = keylocation: {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
              compression = "lz4"; # Fast and space-efficient.
              atime = "off"; # Disables updating access times.
              recordsize = "128K"; # Default block size.
              encryption = "aes-256-gcm";
              keyformat = "passphrase";
              inherit keylocation;
            };
          };
          media = keylocation: {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
              compression = "lz4"; # Fast and space-efficient.
              atime = "off"; # Disables updating access times.
              recordsize = "1M"; # Larger blocks improve performance for large sequential files.
              encryption = "aes-256-gcm";
              keyformat = "passphrase";
              inherit keylocation;
            };
          };
          data = keylocation: {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
              compression = "zstd"; # Better compression for text and PDFs.
              recordsize = "16K"; # Smaller blocks are better for small text files.
              encryption = "aes-256-gcm";
              keyformat = "passphrase";
              inherit keylocation;
            };
          };
        in
          lib.attrsets.mergeAttrsList [
            (namespace "backups" {
              ayako = backup "file:///run/secrets/fs/backups/ayako.key"; # "file://${config.age.secrets."/fs/backups/ayako.key"}";
              dad = backup "file:///run/secrets/fs/backups/dad.key"; # "file://${config.age.secrets."fs/backups/dad.key"}";
              delay = backup "file:///run/secrets/fs/backups/delay.key"; # "file://${config.age.secrets."fs/backups/delay.key"}";
            })

            (namespace "delay" {
              beancount = data "file:///run/secrets/fs/delay/beancount.key"; # "file://${config.age.secrets."fs/delay/beancount.key"}";
              media = media "file:///run/secrets/fs/delay/media.key"; # "file://${config.age.secrets."fs/delay/media.key"}";
            })
          ];
      };
    };
  };
}
