{
  flake,
  inputs,
  ...
}: {
  config,
  lib,
  ...
}: {
  imports = [
    inputs.disko.nixosModules.disko
    flake.modules.nixos.fs-btrfs-common
  ];

  options.node.fs.btrfs.system = with lib; {
    luksPasswordFile = mkOption {
      type = types.path;
      description = ''
        Path to the file containing the disk encryption passphrase.

        Only used at provisioning time to encrypt the disk.
      '';
    };
    disk0 = mkOption {
      type = types.str;
      example = "/dev/disk/by-id/ata-WDC_WDS400T1R0A-68A4W0_21083X800070";
      description = ''
        The path under /dev to the 1st disk used for the system (in mirror config).
      '';
    };
    disk1 = mkOption {
      type = types.str;
      example = "/dev/disk/by-id/ata-WDC_WDS400T1R0A-68A4W0_21083X800070";
      description = ''
        The path under /dev to the 2nd disk used for the system (in mirror config).
      '';
    };
    swapSize = mkOption {
      type = types.str;
      example = "72G";
      description = ''
        The size of the swap partition.

        Usually, equal to the size of the RAM, if hibernate is not required,
        size of RAM + square root of RAM otherwise.
      '';
    };
  };

  config = {
    boot = {
      supportedFilesystems.btrfs = true;

      # Enable mdadm for software RAID.
      initrd = {
        availableKernelModules = ["raid1" "md_mod"];
        kernelModules = ["raid1"];
        supportedFilesystems.btrfs = true;
      };

      loader = {
        systemd-boot.enable = true;
        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = "/boot";
        };
      };
    };

    disko.devices = let
      cfg = config.node.fs.btrfs.system;
    in {
      disk = let
        raid1 = device: {
          type = "disk";
          inherit device;
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                label = "EFI";
                size = "500M";
                type = "EF00";
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
        disk0 = raid1 cfg.disk0;
        disk1 = raid1 cfg.disk1;
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
                start = "-${cfg.swapSize}";
                content = {
                  type = "swap";
                  randomEncryption = true;
                  priority = 100;
                };
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
  };
}
