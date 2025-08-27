{
  nvme0,
  nvme1,
}: {inputs, ...}: {
  imports = [inputs.disko.nixosModules.disko];

  boot = {
    # Enable mdadm for software RAID
    initrd = {
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
    in {
      # System: these SSD are mirrored in RAID1.
      disk0 = raid1 nvme0; # NVMe 1
      disk1 = raid1 nvme1; # NVMe 2
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
              start = "-96G"; # Size of RAM.
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
  };
}
