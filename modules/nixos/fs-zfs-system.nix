{ flake, ... }:
{
  config,
  lib,
  ...
}:
{
  imports = [ flake.modules.nixos.fs-zfs-system-base ];

  options.node.fs.zfs.system = with lib; {
    swapSize = mkOption {
      type = types.str;
      example = "72G";
      description = ''
        The size of the swap partition.

        Usually, equal to the size of the RAM, if hibernate is not required,
        size of RAM + square root of RAM otherwise.

        Do not specify a negative value. The partition is created at the end of
        the disk and is already prefixed by a minus sign.
      '';
    };
  };

  config =
    let
      cfg = config.node.fs.zfs.system;
    in
    {
      boot = {
        supportedFilesystems.vfat = true;
        initrd.supportedFilesystems.vfat = true;
      };

      disko.devices.disk.system.content.partitions = {
        ESP = {
          label = "EFI";
          start = "0"; # Force ESP partition to be the first.
          size = "500M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [
              "defaults"
              "umask=0077"
            ];
          };
        };
        swap = {
          label = "swap";
          start = "-${cfg.swapSize}";
          content = {
            type = "swap";
            randomEncryption = true;
            priority = 100;
          };
        };
      };
    };
}
