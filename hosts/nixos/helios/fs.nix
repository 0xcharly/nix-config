{inputs, ...}: {
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
    in {
      # These disks is mirrored in RAID1.
      disk0 = raid1 "/dev/nvme0n1p1";
      disk1 = raid1 "/dev/nvme1n1p1";
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
  };
}
