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
          # mkPassphraseEncryptionOptions :: String -> AttrSet
          mkPassphraseEncryptionOptions = mountpoint: {
            encryption = "aes-256-gcm";
            keyformat = "passphrase";
            keylocation = "file://${config.age.secrets."zfs/tank/${mountpoint}.key".path}";
          };

          # mkDataset :: AttrSet -> String -> AttrSet
          mkDataset = options: mountpoint: {
            ${mountpoint} = {
              type = "zfs_fs";
              options = {mountpoint = "/tank/${mountpoint}";} // options;
            };
          };

          # mkEncryptedDataset :: AttrSet -> String -> AttrSet
          mkEncryptedDataset = options: mountpoint: {
            ${mountpoint} = {
              type = "zfs_fs";
              options = {mountpoint = "/tank/${mountpoint}";} // (mkPassphraseEncryptionOptions mountpoint) // options;
            };
          };

          # Creates multiple `datasets` under a common root dataset at `mountpoint`.
          #
          # mkNamespaceDataset :: {
          #   mountpoint :: String;
          #   datasets :: { [String] :: (String -> AttrSet) };
          #   options :: AttrSet;
          # } -> AttrSet
          mkNamespaceDataset = {
            mountpoint,
            datasets,
            options ? {},
          }: let
            parent = mkDataset ({mountpoint = "none";} // options) mountpoint;
            mkChildDataset = name: builder: builder "${mountpoint}/${name}";
          in
            parent // (lib.concatMapAttrs mkChildDataset datasets);

          # A dataset for picture files. Better suited for medium-sized files.
          # mkAlbumDataset :: String -> AttrSet
          mkAlbumDataset = mkEncryptedDataset {
            compression = "zstd"; # Better compression for text and PDFs.
            recordsize = "1M"; # Larger blocks improve performance for large sequential files.
          };

          # A dataset for backups.
          # mkBackupDataset :: String -> AttrSet
          mkBackupDataset = mkEncryptedDataset {
            atime = "off"; # Disables updating access times.
            compression = "lz4"; # Fast and space-efficient.
            recordsize = "128K"; # Default block size.
          };

          # A dataset for regular files. Better suited for small files.
          # mkGenericDataset :: String -> AttrSet
          mkGenericDataset = mkEncryptedDataset {
            compression = "zstd"; # Better compression for text and PDFs.
            recordsize = "16K"; # Smaller blocks are better for small text files.
          };

          # A dataset for media files. Better suited for large files.
          # mkMediaDataset :: String -> AttrSet
          mkMediaDataset = mkEncryptedDataset {
            atime = "off"; # Disables updating access times.
            compression = "lz4"; # Fast and space-efficient.
            recordsize = "1M"; # Larger blocks improve performance for large sequential files.
          };

          # Namespaced datasets for hosting the content of repositories.
          # mkForgeDatasets :: String -> AttrSet
          mkForgeDatasets = mountpoint:
            mkNamespaceDataset {
              inherit mountpoint;
              options = mkPassphraseEncryptionOptions mountpoint;
              datasets = {
                # Git LFS dataset.
                data = mkDataset {
                  compression = "lz4"; # Fast and space-efficient.
                  recordsize = "1M"; # Larger blocks improve performance for large sequential files.
                };
                # Git repositories dataset.
                repo = mkDataset {
                  compression = "zstd"; # Better compression for text and PDFs.
                  recordsize = "16K"; # Smaller blocks are better for small text files.
                };
              };
            };
        in
          lib.mergeAttrsList [
            (mkNamespaceDataset {
              mountpoint = "backups";
              datasets = {
                ayako = mkBackupDataset;
                dad = mkBackupDataset;
                delay = mkBackupDataset;
                homelab = mkBackupDataset;
              };
            })

            (mkNamespaceDataset {
              mountpoint = "delay";
              datasets = {
                album = mkAlbumDataset;
                beans = mkGenericDataset;
                files = mkGenericDataset;
                forge = mkForgeDatasets;
                media = mkMediaDataset;
                notes = mkGenericDataset;
                vault = mkGenericDataset;
              };
            })

            (mkNamespaceDataset {
              mountpoint = "ayako";
              datasets = {
                files = mkGenericDataset;
                media = mkMediaDataset;
              };
            })
          ];
      };
    };
  };
}
