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

  options.node.fs.zfs.system = with lib; let
    diskOptions = {
      options = {
        device = mkOption {
          type = types.str;
          example = "/dev/disk/by-id/ata-WDC_WDS400T1R0A-68A4W0_21083X800070";
          description = ''
            The absolute path under /dev/disk/by-id to the disk used for the system (in mirror config).
          '';
        };

        bootPartitionUuid = mkOption {
          type = types.strMatching "[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}";
          example = "809b3a2b-828a-4730-95e1-75b6343e415a";
          description = ''
            The UUID (also known as GUID) of the partition. Note that this is distinct from the UUID of the filesystem.

            You can generate a UUID with the command `uuidgen -r`.
          '';
        };
      };
    };
  in {
    luksPasswordFile = mkOption {
      type = types.path;
      description = ''
        Path to the file containing the disk encryption passphrase.

        Only used at provisioning time to encrypt the disk.
      '';
    };
    disk0 = mkOption {
      type = types.submodule diskOptions;
      description = ''
        The options for the 1st disk used for the system (in mirror config).
      '';
    };
    disk1 = mkOption {
      type = types.submodule diskOptions;
      description = ''
        The options for the 2nd disk used for the system (in mirror config).
      '';
    };
    swapDisk = mkOption {
      type = types.str;
      example = "/dev/disk/by-id/ata-WDC_WDS400T1R0A-68A4W0_21083X800070";
      description = ''
        The path under /dev to the disk dedicated to the swap.
      '';
    };
  };

  config = {
    boot = {
      kernelParams = ["nohibernate"];

      supportedFilesystems.vfat = true;
      initrd = {
        kernelModules = ["zfs"];
        supportedFilesystems = {
          vfat = true;
          zfs = true;
        };
      };
    };

    # "Sync /boot to /boot-fallback on activation.
    system.activationScripts.syncBootFallback = {
      text = ''
        echo "[nix-config] syncing /boot and /boot-fallback"

        # Keep /boot and /boot-fallback in sync on each activation.
        # -a: archive mode (preserves permissions, symlinks, timestamps)
        # -H: preserve hardlinks
        # --delete: remove files on fallback that were deleted on primary
        ${lib.getExe pkgs.rsync} -aH --delete /boot/ /boot-fallback/
      '';
      deps = ["specialfs"]; # Ensure /boot and /boot-fallback are mounted.
    };

    disko.devices = let
      cfg = config.node.fs.zfs.system;
    in {
      disk = let
        mkSystemDisk = {
          device,
          bootPartitionUuid,
        }: luksName: {
          type = "disk";
          inherit device;
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                # IMPORTANT: When `label=` is specified, Disko references to these partitions by
                # label in /etc/fstab. They MUST be distinct per disk, otherwise this will mount
                # the same partition twice.
                # This config originally assign the same label to both disk, causing a race when
                # mounting /boot and /boot-fallback, effectively causing one of these partitions
                # to be mounted twice, and /boot and /boot-fallback to point to it (/etc/fstab).
                # This caused sync-boot-fallback.service to be a noop.
                # Luckily disko prefers using the partition UUID if specified. This permitted to
                # safely untangle this mess remotly without crashing the system, since deploying
                # a new configuration triggers boot.service and boot-fallback.service.
                # Partition labels were manually fixed with gdisk to match the comment below.

                # label =
                #   if device == cfg.disk0.device
                #   then "EFI0"
                #   else "EFI1";

                uuid = bootPartitionUuid;
                name = "ESP";
                size = "500M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint =
                    if bootPartitionUuid == cfg.disk0.bootPartitionUuid
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
    };
  };
}
