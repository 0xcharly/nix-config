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

    # Argon2id benchmarks its MEMORY cost on the machine running luksFormat:
    # the 4GB wipe-window installer bakes in ~1GiB, and the 1GB Nanode then
    # OOMs in initrd at every unlock (systemd-cryptsetup killed at ~725MB —
    # gate-fr, 2026-08-07; healed post-hoc with `cryptsetup luksConvertKey
    # --pbkdf-memory 131072`). Bound it at format time: 128MiB fits the
    # Nanode alongside the initrd + hoopsnake, and the vault passphrases are
    # long random strings — KDF hardness is not the security margin here.
    disko.devices.disk.system.content.partitions.luks.content.extraFormatArgs = [
      "--pbkdf-memory=131072"
    ];

    # The memoryPercent = 50 default is right for the 1GB Nanodes.
    zramSwap.enable = true;
    # Priorities need no tuning: zramSwap registers at high priority and the
    # disko swapfile's swapDevices entry defaults to a negative one, so zram is
    # tried before the disk. Verified post-install via `swapon --show` — a
    # backwards ordering silently gives disk-speed eviction with zram idle.
  };
}
