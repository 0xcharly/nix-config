{
  flake.nixosModules.fs-btrfs-root-linode = {
    boot = {
      supportedFilesystems.ext4 = true;
      initrd.supportedFilesystems.ext4 = true;
    };

    disko.devices.disk.system.content.partitions = {
      bios = {
        start = "0"; # Force boot partition to be the first
        size = "1M";
        type = "EF02"; # BIOS boot partition (for GRUB in BIOS mode)
      };
      boot = {
        size = "512M";
        content = {
          type = "filesystem";
          format = "ext4";
          mountpoint = "/boot";
        };
      };
    };

    # The memoryPercent = 50 default is right for the 1GB Nanodes.
    zramSwap.enable = true;
    # Priorities need no tuning: zramSwap registers at high priority and the
    # disko swapfile's swapDevices entry defaults to a negative one, so zram is
    # tried before the disk. Verified post-install via `swapon --show` — a
    # backwards ordering silently gives disk-speed eviction with zram idle.
  };
}
