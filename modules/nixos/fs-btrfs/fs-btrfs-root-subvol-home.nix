{
  flake.nixosModules.fs-btrfs-root-subvol-home = {
    disko.devices.disk.system.content.partitions.luks.content.content.subvolumes."@home" = {
      mountpoint = "/home";
      mountOptions = [
        "compress=zstd"
        "noatime"
      ];
    };
  };
}
