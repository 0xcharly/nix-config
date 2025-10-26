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

    # TODO: There is something fishy happening with this.
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
    };
  };
}
