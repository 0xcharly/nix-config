{inputs, ...}: {
  imports = [inputs.disko.nixosModules.disko];

  disko.devices = {
    disk = {
      SYSTEM = {
        device = "/dev/nvme0n1";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              label = "boot";
              type = "EF00"; # UEFI
              # type = "EF02"; # Grub MBR
              start = "1M";
              end = "512M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            swap = {
              priority = 2;
              label = "swap";
              start = "-72G"; # Size of RAM + square root of RAM. Required for hibernation.
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
