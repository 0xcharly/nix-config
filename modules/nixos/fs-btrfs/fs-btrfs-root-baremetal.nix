{
  flake.nixosModules.fs-btrfs-root-baremetal = {
    boot = {
      supportedFilesystems.vfat = true;
      initrd.supportedFilesystems.vfat = true;
    };

    disko.devices.disk.system.content.partitions.ESP = {
      label = "EFI";
      start = "0"; # Force ESP partition to be the first
      size = "500M";
      type = "EF00";
      content = {
        type = "filesystem";
        format = "vfat";
        mountpoint = "/boot";
        mountOptions = [
          "defaults"
          "umask=0077"
        ];
      };
    };

    zramSwap = {
      enable = true;
      # 50% default would advertise a 32G compressed device on the 64G boxes —
      # harmless, but trim to reflect intent.
      memoryPercent = 25;
    };
    # Priorities need no tuning: zramSwap registers at high priority and the
    # disko swapfile's swapDevices entry defaults to a negative one, so zram is
    # tried before the disk. Verified post-install via `swapon --show` — a
    # backwards ordering silently gives disk-speed eviction with zram idle.
  };
}
