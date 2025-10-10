{flake, ...}: {
  config,
  lib,
  ...
}: {
  imports = [flake.modules.nixos.fs-zfs-system-base];

  options.node.fs.zfs.system.linode = with lib; {
    swapDisk = mkOption {
      type = types.str;
      example = "/dev/sdb";
      description = ''
        The path under /dev to the disk used for the swap.
      '';
    };
  };

  config = let
    cfg = config.node.fs.zfs.system.linode;
  in {
    boot = {
      supportedFilesystems.ext4 = true;
      initrd.supportedFilesystems.ext4 = true;

      loader.grub = {
        enable = true;
        device = "nodev";
        forceInstall = true;
      };
    };

    disko.devices.disk = {
      system.content.partitions = {
        bios = {
          start = "0"; # Force boot partition to be the first.
          size = "1M";
          type = "EF02"; # BIOS boot partition (for GRUB in BIOS mode)
        };
        boot = {
          size = "512M";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/boot";
          };
        };
      };
      swapDisk = {
        type = "disk";
        device = cfg.swapDisk;
        content = {
          type = "swap";
          randomEncryption = true;
          priority = 100;
        };
      };
    };
  };
}
