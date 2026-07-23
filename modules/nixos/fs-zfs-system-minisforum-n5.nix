# ARCHITECTURAL NOTE: DUAL BOOT PARTITION DESIGN
#
# To prevent catastrophic boot failures on LUKS-encrypted systems (especially
# remote nodes), this machine maintains two mirrored EFI System Partitions
# (ESPs): `/boot` (Primary) and `/boot-fallback` (Secondary).
#
# RISK PROFILE & BOOT PRIORITIZATION
#
# The motherboard/BIOS should be explicitly configured to attempt booting from
# the SECONDARY partition (`/boot-fallback`) by default.
#
# When NixOS installs the bootloader (`nixos-rebuild switch` or
# `nixos-rebuild boot`), it writes the new generation files directly to
# `/boot`. The systemd-boot installer (via
# `boot.loader.systemd-boot.extraInstallCommands`) then `rsync`s `/boot` over
# to `/boot-fallback`. This makes `/boot` our immutable source of truth. By
# booting off `/boot-fallback` for daily operations, any sudden power failures,
# file system corruption, or emergency-mode lockouts will only impact the
# fallback drive. If the fallback drive becomes corrupted, the hardware BIOS can
# be configured to failover to the pristine, untouched primary `/boot`
# partition.
#
# When booting off the fallback drive, systemd's `bootctl` will report a
# partition UUID mismatch warning. This is expected and safe to ignore.
#
# RECOVERY PROCEDURE IN CASE OF CORRUPTION
#
# After rebooting the machine from to the primary `/boot` drive due to
# corruption on the fallback drive:
#
# 1. Log into the system (which should boot successfully via the primary `/boot`
#    drive).
# 2. Rectify any underlying configuration issues that caused a system panic.
# 3. Execute `sudo nixos-rebuild switch` (or `sudo nixos-rebuild boot`).
#
# Because the sync runs as part of the bootloader installer, it will read the
# healthy data from `/boot` and overwrite/repair the corrupted `/boot-fallback`
# partition whenever the bootloader is (re)installed.
#
# No manual `fsck` or partition formatting should be required; the declarative
# rebuild cycle should restore the mirror.
#
# MANUAL FILESYSTEM VERIFICATION & REPAIR (fsck)
#
# To manually inspect the partitions for structural or file allocation table
# corruption (e.g., following a hard power cycle), use the following procedure.
#
# Note: Linux vFAT drivers flip the dirty bit to '1' immediately upon mounting,
# so running a check on a mounted partition will always report a false-positive
# dirty bit.
#
# 1. Inspect without modifying (Safe while mounted, ignores the dirty bit
#    warning):
#
#    $ sudo fsck.vfat -n /dev/disk/by-partuuid/<UUID>
#
# 2. To safely repair errors or clear stale dirty bits, the target partition
#    MUST be unmounted first to prevent filesystem collision:
#
#    $ sudo umount /boot         # Or /boot-fallback depending on the target
#    $ sudo fsck.vfat -a /dev/disk/by-partuuid/<UUID>
#    $ sudo mount /boot
#
# Part UUID are recorded in this config and show in /etc/fstab.

{ inputs, ... }:
{
  flake.nixosModules.fs-zfs-system-minisforum-n5 =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.disko.nixosModules.disko ];

      options.node.fs.zfs.system =
        with lib;
        let
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
        in
        {
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
          kernelParams = [ "nohibernate" ];

          supportedFilesystems.vfat = true;
          initrd = {
            kernelModules = [ "zfs" ];
            supportedFilesystems = {
              vfat = true;
              zfs = true;
            };
          };
        };

        # Await LUKS prompt
        # https://github.com/nix-community/disko/issues/1257
        fileSystems."/".options = [ "x-systemd.device-timeout=infinity" ];

        # Sync /boot to /boot-fallback whenever the bootloader is (re)installed.
        # Unlike activation scripts (which only run on `switch`/`test`),
        # `extraInstallCommands` is appended to the bootloader installer that
        # switch-to-configuration runs for BOTH the `switch` and `boot` actions,
        # so the mirror stays in sync on `nixos-rebuild boot` and `deploy --boot`.
        boot.loader.systemd-boot.extraInstallCommands = ''
          if ${lib.getExe' pkgs.util-linux "mountpoint"} -q /boot \
              && ${lib.getExe' pkgs.util-linux "mountpoint"} -q /boot-fallback; then
            echo "[nix-config] syncing /boot and /boot-fallback"
            # -a: archive mode (preserves permissions, symlinks, timestamps)
            # -H: preserve hardlinks
            # --delete: remove files on fallback that were deleted on primary
            ${lib.getExe pkgs.rsync} -aH --delete /boot/ /boot-fallback/
          else
            echo "[nix-config] WARNING: /boot or /boot-fallback not mounted; skipping ESP mirror sync" >&2
          fi
        '';

        disko.devices =
          let
            cfg = config.node.fs.zfs.system;
          in
          {
            disk =
              let
                mkSystemDisk =
                  {
                    device,
                    bootPartitionUuid,
                  }:
                  luksName: {
                    type = "disk";
                    inherit device;
                    content = {
                      type = "gpt";
                      partitions = {
                        ESP = {
                          # IMPORTANT: When `label=` is specified, Disko references to these partitions by
                          # label in /etc/fstab. They MUST be distinct per disk, otherwise this will mount
                          # the same partition twice.
                          # This config originally assigned the same label to both disks, introducing a race when
                          # mounting /boot and /boot-fallback, effectively causing one of these partitions to be
                          # mounted twice, and /boot and /boot-fallback to point to it (/etc/fstab). This caused
                          # sync-boot-fallback.service to be a noop.
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
                            mountpoint = if bootPartitionUuid == cfg.disk0.bootPartitionUuid then "/boot" else "/boot-fallback";
                            mountOptions = [
                              "defaults"
                              "umask=0077"
                            ];
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
              in
              {
                # System: these SSD are mirrored with ZFS
                disk0 = mkSystemDisk cfg.disk0 "crypted0"; # NVMe 1
                disk1 = mkSystemDisk cfg.disk1 "crypted1"; # NVMe 2
                # Swap: overkill, but the Minisforum N5 comes with a 128GB NVMe drive…
                swapDisk = mkSwapDisk cfg.swapDisk;
              };
          };
      };
    };
}
