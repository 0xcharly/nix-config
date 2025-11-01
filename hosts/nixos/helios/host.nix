{modulesPath, ...}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # System config.
  node = {
    hardware = {
      cpu.vendor = "amd";
      gpu.vendor = "intel";
      rgb.disable = true;
    };

    services = {
      calibre.enable = true;
      immich.enable = false; # 2025-11-01: migrated to bowmore.
      jellyfin.enable = true;
      paperless.enable = true;
      prometheus.exporters = {
        node.enable = true;
        zfs.enable = true;
      };
    };
  };

  modules.system = {
    security.accessTier = "trusted";
    networking.tailscaleNode = true;
  };

  modules.system.roles.nas = {
    enable = true;
    primary = true;
    hostId = "a514e9b4";
    drives = {
      nvme0 = "/dev/disk/by-id/nvme-Samsung_SSD_980_500GB_S78GNL0XC07939J"; # Front NVMe
      nvme1 = "/dev/disk/by-id/nvme-Samsung_SSD_980_500GB_S78GNL0X725101A"; # Back NVMe
      sata0 = "/dev/disk/by-id/ata-ST24000NT002-3N1101_ZYD2NSJF"; # SATA 1
      sata1 = "/dev/disk/by-id/ata-ST24000NT002-3N1101_ZYD2AXL9"; # SATA 2
      sata2 = "/dev/disk/by-id/ata-ST24000NT002-3N1101_ZYD2Q5E4"; # SATA 3
      sata3 = "/dev/disk/by-id/ata-ST24000NT002-3N1101_ZYD1YVZ0"; # SATA 4
    };
  };

  # Network config.
  networking.interfaces.enp11s0.useDHCP = true;
}
