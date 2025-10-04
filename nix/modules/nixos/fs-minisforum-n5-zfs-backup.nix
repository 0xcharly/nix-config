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
    flake.modules.nixos.fs-zfs-common
  ];

  options.node.fs.zfs.backup = with lib; {
    disk0 = mkOption {
      type = types.str;
      example = "/dev/disk/by-id/ata-WDC_WDS400T1R0A-68A4W0_21083X800070";
      description = ''
        The path under /dev to the 1st disk.
      '';
    };
    disk1 = mkOption {
      type = types.str;
      example = "/dev/disk/by-id/ata-WDC_WDS400T1R0A-68A4W0_21083X800070";
      description = ''
        The path under /dev to the 2nd disk.
      '';
    };
    disk2 = mkOption {
      type = types.str;
      example = "/dev/disk/by-id/ata-WDC_WDS400T1R0A-68A4W0_21083X800070";
      description = ''
        The path under /dev to the 3rd disk.
      '';
    };
    disk3 = mkOption {
      type = types.str;
      example = "/dev/disk/by-id/ata-WDC_WDS400T1R0A-68A4W0_21083X800070";
      description = ''
        The path under /dev to the 4th disk.
      '';
    };
    disk4 = mkOption {
      type = types.str;
      example = "/dev/disk/by-id/ata-WDC_WDS400T1R0A-68A4W0_21083X800070";
      description = ''
        The path under /dev to the 5th disk.
      '';
    };
  };

  config.disko.devices = let
    cfg = config.node.fs.zfs.backup;
  in {
    disk = let
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
      # Backup: these HDD are set up in RAIDZ1.
      data0 = zpool cfg.disk0; # SATA 1
      data1 = zpool cfg.disk1; # SATA 2
      data2 = zpool cfg.disk2; # SATA 3
      data3 = zpool cfg.disk3; # SATA 4
      data4 = zpool cfg.disk4; # SATA 5
    };
    zpool = {
      tank = {
        type = "zpool";
        mode = "raidz1";
        rootFsOptions = {
          canmount = "off";
          checksum = "edonr";
          compression = "zstd";
          dnodesize = "auto";
          mountpoint = "none";
          normalization = "none";
          relatime = "on";
          "com.sun:auto-snapshot" = "false";
        };
        options.ashift = "12";
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
          # A dataset for backups.
          mkBackupDataset = name: {
            ${name} = {
              type = "zfs_fs";
              options = {
                mountpoint = "/tank/backups/${name}";
                compression = "lz4"; # Fast and space-efficient.
                atime = "off"; # Disables updating access times.
                recordsize = "128K"; # Default block size.
                encryption = "aes-256-gcm";
                keyformat = "passphrase";
                keylocation = "file://${config.age.secrets."zfs/tank/backups/${name}.key".path}";
              };
            };
          };
          # A dataset for regular files. Better suited for small files.
          mkAlbumDataset = mountpoint: {
            type = "zfs_fs";
            options = {
              mountpoint = "/tank/${mountpoint}";
              compression = "zstd"; # Better compression for text and PDFs.
              recordsize = "1M"; # Larger blocks improve performance for large sequential files.
              encryption = "aes-256-gcm";
              keyformat = "passphrase";
              keylocation = "file://${config.age.secrets."zfs/tank/${mountpoint}.key".path}";
            };
          };
          # A dataset for regular files. Better suited for small files.
          mkGenericDataset = mountpoint: {
            type = "zfs_fs";
            options = {
              mountpoint = "/tank/${mountpoint}";
              compression = "zstd"; # Better compression for text and PDFs.
              recordsize = "16K"; # Smaller blocks are better for small text files.
              encryption = "aes-256-gcm";
              keyformat = "passphrase";
              keylocation = "file://${config.age.secrets."zfs/tank/${mountpoint}.key".path}";
            };
          };
          # A dataset for media files. Better suited for large files.
          mkMediaDataset = mountpoint: {
            type = "zfs_fs";
            options = {
              mountpoint = "/tank/${mountpoint}";
              compression = "lz4"; # Fast and space-efficient.
              atime = "off"; # Disables updating access times.
              recordsize = "1M"; # Larger blocks improve performance for large sequential files.
              encryption = "aes-256-gcm";
              keyformat = "passphrase";
              keylocation = "file://${config.age.secrets."zfs/tank/${mountpoint}.key".path}";
            };
          };

          mkBackupDatasets = datasets: lib.mergeAttrsList (builtins.map mkBackupDataset datasets);
        in
          lib.mergeAttrsList [
            (namespace "backups" (mkBackupDatasets [
              "ayako"
              "dad"
              "delay"
              "homelab"
            ]))

            (namespace "delay" {
              album = mkAlbumDataset "delay/album";
              beans = mkGenericDataset "delay/beans";
              files = mkGenericDataset "delay/files";
              media = mkMediaDataset "delay/media";
              notes = mkGenericDataset "delay/notes";
              vault = mkGenericDataset "delay/vault";
            })

            (namespace "ayako" {
              files = mkGenericDataset "ayako/files";
              media = mkMediaDataset "ayako/media";
            })
          ];
      };
    };
  };
}
