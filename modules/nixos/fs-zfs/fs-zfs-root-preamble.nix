{ self, inputs, ... }:
{
  # Merge of the former fs-zfs-common + fs-zfs-zpool-root modules (the
  # NAS-only ZFS base, mirroring the fs-btrfs-root-preamble layout).
  # Reporting is mandatory wherever the ZFS root preamble is used, matching
  # the btrfs profiles: this module carries prometheus-exporters-zfs.
  flake.nixosModules.fs-zfs-root-preamble =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        inputs.disko.nixosModules.disko
        self.nixosModules.prometheus-exporters-zfs
      ];

      options.node.fs.zfs = with lib; {
        hostId = mkOption {
          type = types.nullOr types.str;
          example = "4e98920d";
          default = "";
          description = ''
            The 32-bit host ID of the machine, formatted as 8 hexadecimal characters.

            You should try to make this ID unique among your machines. You can
            generate a random 32-bit ID using the following commands:

            `head -c 8 /etc/machine-id`

            (this derives it from the machine-id that systemd generates) or

            `head -c4 /dev/urandom | od -A none -t x4`

            The primary use case is to ensure when using ZFS that a pool isn't imported
            accidentally on a wrong machine.

            https://search.nixos.org/options?channel=unstable&query=networking.hostId
          '';
        };

        zpool.root.reservation = mkOption {
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

      config =
        let
          cfg = config.node.fs.zfs;
        in
        {
          # The primary use case is to ensure when using ZFS that a pool isn’t imported
          # accidentally on a wrong machine.
          # https://search.nixos.org/options?channel=unstable&query=networking.hostId
          networking = { inherit (cfg) hostId; };

          boot = {
            swraid.mdadmConf = ''
              MAILADDR root
            '';

            kernelModules = [ "zfs" ];
            supportedFilesystems.zfs = true;

            # IMPORTANT NOTE: LTS Linux Kernel is the recommended setup for ZFS
            # (also NixOS default).
            # https://discourse.nixos.org/t/zfs-latestcompatiblelinuxpackages-is-deprecated/52540
            # https://github.com/openzfs/zfs/releases
            kernelPackages = pkgs.linuxPackages;
            zfs.package = pkgs.zfs_2_4;

            # When true, forcibly import the ZFS root pool(s) during early boot.
            # It is highly recommended to keep this option disabled as it
            # bypasses ZFS safeguard that protect your pools.
            # You should only need to do this after unclean shutdowns.
            # This is `false` for every hosts in this configuration. The
            # `lib.mkForce` verifies that.
            zfs.forceImportRoot = lib.mkForce false;
          };

          # Scrub all pools, monthly by default
          services.zfs.autoScrub.enable = true;

          environment.systemPackages = [
            pkgs.httm # Snapshot browsing
            config.boot.zfs.package
          ];

          disko.devices.zpool.root = {
            type = "zpool";
            rootFsOptions = {
              acltype = "posixacl"; # Required for systemd-journald: https://github.com/NixOS/nixpkgs/issues/16954#issuecomment-250578128
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
            datasets = {
              reserved = {
                type = "zfs_fs";
                options = {
                  canmount = "off";
                  mountpoint = "none";
                  inherit (cfg.zpool.root) reservation;
                };
              };
              root = self.lib.zfs.mkLegacyDataset "/" { };
              nix = self.lib.zfs.mkLegacyDataset "/nix" { atime = "off"; };
            };
          };
        };
    };
}
