{
  flake,
  inputs,
  ...
}: {
  config,
  lib,
  pkgs,
  ...
}: {
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
    reservation = mkOption {
      type = types.str;
      default = "20GiB";
      description = ''
        ZFS uses Copy-on-Write (CoW). That means when the pool is 100% full,
        it can’t overwrite in place — even deleting files requires free
        space (to update metadata). If the pool fills completely, ZFS can
        get into a state where it’s stuck and can’t free space cleanly.

        - Create a hidden dataset (reserved) with a reservation property.
        - If the pool ever does fill up, destroy or shrink this reserved
          dataset to instantly free up some space and let ZFS recover.

        This is a safety cushion for the whole pool. It's never mounted or
        used — it’s just insurance.
      '';
    };
    datadirs = let
      datasetType = types.submodule {
        mountpoint = mkOption {
          type = types.str;
          description = ''
            Relative path under /var/lib.
          '';
        };
        extraOptions = mkOption {
          type = types.attrsOf types.str;
          default = {};
          description = ''
            Additional options to set on the dataset.
          '';
        };
        user = mkOption {
          type = types.str;
          default = "root";
          description = ''
            The owning user of this directory.
          '';
        };
        group = mkOption {
          type = types.str;
          default = "users";
          description = ''
            The owning group of this directory.
          '';
        };
        mode = mkOption {
          type = types.str;
          default = "0755";
          description = ''
            The permissions to set on this directory.
          '';
        };
      };
    in
      mkOption {
        type = types.listOf datasetType;
        default = [];
        description = ''
          List of additional datasets to create under /var/lib.
        '';
      };
  };

  config = let
    cfg = config.node.fs.zfs.system;
  in {
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

    disko.devices = {
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
              start = "-${cfg.swapSize}";
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
                  type = "zfs";
                  pool = "root";
                };
              };
            };
          };
        };
      };
      zpool.root = {
        type = "zpool";
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
        options = {
          ashift = "12";
          autotrim = "on";
        };
        datasets = let
          mkDataset = mountpoint: options: {
            type = "zfs_fs";
            inherit mountpoint;
            options =
              {
                mountpoint = "legacy";
                canmount = "on";
                "com.sun:auto-snapshot" = "false";
              }
              // options;
          };
        in
          {
            reserved = {
              type = "zfs_fs";
              options = {
                canmount = "off";
                mountpoint = "none";
                inherit (cfg) reservation;
              };
            };
            root = mkDataset "/" {};
            home = mkDataset "/home" {};
            nix = mkDataset "/nix" {atime = "off";};
            datadir = mkDataset "/var/lib" {};
          }
          // lib.mergeAttrsList (builtins.map (dataset: {
              "datadir-${dataset.mountpoint}" = mkDataset "/var/lib/${dataset.mountpoint}" {};
            })
            cfg.datasets);
      };
    };

    # Automatically adjust datadirs' permissions, if any.
    systemd.services = lib.mkIf (cfg.datadirs != []) {
      set-datadir-perms = {
        description = "Adjust datadirs' perms";

        # Wait for the agenix service to be running / complete before mounting the ZFS pool.
        after = ["zfs-import.target"];
        requires = ["zfs-import.target"];
        wantedBy = ["multi-user.target"];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = let
            install-datadir = datadir: ''
              install -d --mode ${datadir.mode} --owner ${datadir.owner} --group ${datadir.group} /var/lib/${datadir.mountpoint}
            '';
            set-datadir-perms = pkgs.writeShellApplication {
              name = "set-datadir-perms";
              runtimeInputs = with pkgs; [coreutils zfs];
              text = lib.concatStringsSep "\n" (builtins.map install-datadir cfg.datadirs);
            };
          in
            lib.getExe set-datadir-perms;
        };
      };
    };
  };
}
