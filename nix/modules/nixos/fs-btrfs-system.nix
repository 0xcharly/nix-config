{flake, ...}: {
  config,
  lib,
  inputs,
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
    disk = mkOption {
      type = types.str;
      example = "/dev/disk/by-id/ata-WDC_WDS400T1R0A-68A4W0_21083X800070";
      description = ''
        The path under /dev to the disk used for the system.
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
      supportedFilesystems = ["vfat"];

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
      disk.system = {
        type = "disk";
        device = cfg.disk;
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              label = "EFI";
              size = "500M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["defaults" "umask=0077"];
              };
            };
            swap = {
              label = "swap";
              start = cfg.swapSize;
              content = {
                type = "swap";
                randomEncryption = true;
                priority = 100;
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";
                settings.allowDiscards = true;
                passwordFile = cfg.luksPasswordFile;
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
