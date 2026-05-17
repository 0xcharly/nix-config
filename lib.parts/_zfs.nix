{
  mkLegacyDataset = mountpoint: options: {
    type = "zfs_fs";
    inherit mountpoint;
    options = {
      canmount = "on";
      mountpoint = "legacy";
      "com.sun:auto-snapshot" = "false";
    }
    // options;
  };

  redis-dataset-options = {
    atime = "off"; # Redis doesn’t need access-time tracking.
    compression = "zstd";
    dedup = "off"; # Pointless for Redis — data patterns change frequently.
    logbias = "throughput"; # Redis already buffers writes; favor sequential throughput.
    primarycache = "metadata"; # Avoid double caching Redis’s dataset in ARC since it’s already in RAM.
    recordsize = "128K"; # Redis writes large RDB dumps sequentially; AOF writes are append-heavy. Larger blocks reduce overhead.
    secondarycache = "metadata"; # Same reasoning for L2ARC.
  };
}
