# This file is normally automatically generated. Since we build a VM
# and have full control over that hardware I can hardcode this into my
# repository.
{inputs, ...}: {
  imports = [inputs.disko.nixosModules.disko];

  disko.devices = {
    disk = {
      SYSTEM = {
        device = "/dev/sda";
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
              start = "-8G";
              content.type = "swap";
            };
            nixos = {
              priority = 3;
              label = "nixos";
              size = "100%"; # Remainder of the disk.
              content = {
                type = "btrfs";
                subvolumes = {
                  "/" = {
                    mountpoint = "/";
                    mountOptions = ["compress=zstd"];
                  };
                  "/nix" = {
                    mountOptions = ["compress=zstd" "noatime"];
                  };
                };
                mountpoint = "/nixos";
              };
            };
          };
        };
      };
    };
  };
}
# TODO: delete original config once the above one is confirmed to work.
# {
#   fileSystems."/" = {
#     device = "/dev/disk/by-label/nixos";
#     fsType = "ext4";
#   };
#
#   fileSystems."/boot" = {
#     device = "/dev/disk/by-label/boot";
#     fsType = "vfat";
#     options = ["umask=0077"];
#   };
#
#   swapDevices = [{device = "/dev/disk/by-label/swap";}];
# }
