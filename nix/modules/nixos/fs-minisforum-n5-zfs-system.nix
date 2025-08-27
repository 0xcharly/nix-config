{flake, ...}: {
  config,
  lib,
  pkgs,
  inputs,
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
    swapDisk = mkOption {
      type = types.str;
      example = "/dev/disk/by-id/ata-WDC_WDS400T1R0A-68A4W0_21083X800070";
      description = ''
        The path under /dev to the disk dedicated to the swap.
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

    systemd.services.sync-boot-fallback = {
      description = "Sync /boot to /boot-fallback after boot";
      after = ["local-fs.target" "zfs-mount.service"];
      wants = ["zfs-mount.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = flake.lib.builders.mkShellApplication pkgs {
          name = "sync-boot-fallback";
          runtimeInputs = with pkgs; [rsync];
          text = ''
            # Keep /boot and /boot-fallback in sync.
            # -a: archive mode (preserves permissions, symlinks, timestamps)
            # -H: preserve hardlinks
            # --delete: remove files on fallback that were deleted on primary
            rsync -aH --delete /boot/ /boot-fallback/
          '';
        };
      };
      wantedBy = ["multi-user.target"];
    };

    disko.devices = let
      cfg = config.node.fs.zfs.system;
    in {
      disk = let
        mkSystemDisk = device: luksName: {
          type = "disk";
          inherit device;
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                label = "EFI";
                name = "ESP";
                size = "500M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint =
                    if device == cfg.disk0
                    then "/boot"
                    else "/boot-fallback";
                  mountOptions = ["defaults" "umask=0077"];
                };
              };
              luks = {
                size = "100%";
                content = {
                  type = "luks";
                  name = luksName;
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
        mkSwapDisk = device: {
          type = "disk";
          inherit device;
          content = {
            type = "swap";
            randomEncryption = true;
            priority = 100;
          };
        };
      in {
        # System: these SSD are mirrored with ZFS.
        disk0 = mkSystemDisk cfg.disk0 "crypted0"; # NVMe 1
        disk1 = mkSystemDisk cfg.disk1 "crypted1"; # NVMe 2
        # Swap: overkill, but the Minisforum N5 comes with a 128GB NVMe drive…
        swapDisk = mkSwapDisk cfg.swapDisk;
      };
      zpool = {
        root = {
          type = "zpool";
          mode = "mirror";
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
            mkPostCreateHook = dataset:
              pkgs.writeShellApplication {
                name = "post-create-hook-${dataset}";
                runtimeInputs = with pkgs; [zfs];
                text = ''
                  zfs snapshot root/${dataset}@empty
                '';
              };
          in {
            # ZFS uses CoW free space to delete files when the disk is completely filled.
            reserved = {
              type = "zfs_fs";
              options = {
                canmount = "off";
                mountpoint = "none";
                inherit (cfg) reservation;
              };
            };
            # Nix store etc. Needs to persist, but doesn't need backed up
            nix = {
              type = "zfs_fs";
              mountpoint = "/nix";
              options = {
                mountpoint = "legacy";
                atime = "off";
                canmount = "on";
                "com.sun:auto-snapshot" = "false";
              };
              postCreateHook = lib.getExe (mkPostCreateHook "nix");
            };
            # Where everything else lives, and is wiped on reboot by restoring a blank zfs snapshot.
            root = {
              type = "zfs_fs";
              mountpoint = "/";
              options = {
                mountpoint = "legacy";
                "com.sun:auto-snapshot" = "false";
              };
              postCreateHook = lib.getExe (mkPostCreateHook "root");
            };
          };
        };
      };
    };
  };
}
