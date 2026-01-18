{
  flake,
  inputs,
  ...
}:
{
  config,
  lib,
  ...
}:
{
  imports = [
    inputs.disko.nixosModules.disko
    flake.modules.nixos.fs-zfs-common
  ];

  options.node.fs.zfs.system = with lib; {
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
  };

  config =
    let
      cfg = config.node.fs.zfs.system;
    in
    {
      boot.initrd = {
        kernelModules = [ "zfs" ];
        supportedFilesystems.zfs = true;
      };

      disko.devices.disk.system = {
        type = "disk";
        device = cfg.disk;
        content = {
          type = "gpt";
          partitions.luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "crypted";
              settings.allowDiscards = true;
              passwordFile = cfg.luksPasswordFile;
              content = {
                type = "zfs";
                pool = "root";
              };
            };
          };
        };
      };
    };
}
