{
  mkLegacyDataset = mountpoint: options: {
    type = "zfs_fs";
    inherit mountpoint;
    options =
      {
        canmount = "on";
        mountpoint = "legacy";
        "com.sun:auto-snapshot" = "false";
      }
      // options;
  };
}
