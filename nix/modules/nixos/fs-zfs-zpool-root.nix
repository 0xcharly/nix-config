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

  options.node.fs.zfs.zpool.root = with lib; {
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

  config = let
    cfg = config.node.fs.zfs.zpool.root;
  in {
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
            inherit (cfg) reservation;
          };
        };
        root = flake.lib.zfs.mkLegacyDataset "/" {};
        nix = flake.lib.zfs.mkLegacyDataset "/nix" {atime = "off";};
      };
    };
  };
}
