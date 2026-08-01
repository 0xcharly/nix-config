{ inputs, ... }:
{
  flake.nixosModules.fs-btrfs-root-preamble =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.disko.nixosModules.disko ];

      options.node.fs.btrfs.root = with lib; {
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
          example = "4G";
          description = ''
            The size of the swapfile created in the @swap subvolume.

            Backs the zram device configured alongside; no host hibernates, so
            it does not need to match RAM size.
          '';
        };
      };

      config =
        let
          cfg = config.node.fs.btrfs.root;
        in
        {
          boot = {
            supportedFilesystems.btrfs = true;
            initrd.supportedFilesystems.btrfs = true;
          };

          environment.systemPackages = with pkgs; [
            httm # Snapshot browsing
          ];

          services.btrfs.autoScrub = {
            enable = true; # monthly by default
            # One entry only: the default scrubs the same device once per
            # mountpoint (/, /nix, /persist, …).
            fileSystems = [ "/" ];
          };
          # Instead of discard mount options.
          services.fstrim.enable = true;

          # Await LUKS prompt
          # https://github.com/nix-community/disko/issues/1257
          fileSystems."/".options = [ "x-systemd.device-timeout=infinity" ];

          fileSystems."/persist".neededForBoot = true;

          disko.devices.disk.system = {
            type = "disk";
            device = cfg.disk;
            # Only used by VM tests (vmWithDisko / nixos-anywhere --vm-test):
            # the default 2G image cannot fit the ESP plus the swapfile.
            imageSize = "8G";
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
                    type = "btrfs";
                    extraArgs = [
                      "-L"
                      "nixos"
                      "-f"
                    ];
                    # Blank read-only snapshot of @root: the boot-time rollback
                    # target restored by the rollback-root initrd service.
                    postCreateHook = ''
                      MNTPOINT=$(mktemp -d)
                      mount -t btrfs -o subvol=/ /dev/mapper/crypted "$MNTPOINT"
                      trap 'umount "$MNTPOINT"; rm -rf "$MNTPOINT"' EXIT
                      btrfs subvolume snapshot -r "$MNTPOINT/@root" "$MNTPOINT/@root-blank"
                    '';
                    subvolumes = {
                      "@root" = {
                        mountpoint = "/";
                        mountOptions = [
                          "compress=zstd"
                          "noatime"
                        ];
                      };
                      "@nix" = {
                        mountpoint = "/nix";
                        mountOptions = [
                          "compress=zstd"
                          "noatime"
                        ];
                      };
                      "@persist" = {
                        mountpoint = "/persist";
                        mountOptions = [
                          "compress=zstd"
                          "noatime"
                        ];
                      };
                      "@swap" = {
                        mountpoint = "/.swap";
                        mountOptions = [ "noatime" ];
                        # disko creates it via `btrfs filesystem mkswapfile`
                        # (nodatacow) and emits the swapDevices entry.
                        swap.swapfile.size = cfg.swapSize;
                      };
                    };
                  };
                };
              };
            };
          };
        };
    };
}
