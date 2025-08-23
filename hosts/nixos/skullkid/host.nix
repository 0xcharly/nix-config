{modulesPath, ...}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # System config.
  node = {
    hardware = {
      cpu.vendor = "intel";
      thunderbolt.enable = true;
    };
    services.prometheus.exporters = {
      node.enable = true;
      zfs.enable = true;
    };
  };
  modules.system = {
    security.accessTier = "trusted";
    networking.tailscaleNode = true;
  };

  modules.system.roles.nas = {
    enable = true;
    primary = false;
    hostId = "be2d9ac0";
    drives = {
      nvme0 = "/dev/disk/by-id/nvme-Samsung_SSD_950_PRO_512GB_S2GMNCAGB32083T"; # NVMe ?
      nvme1 = "/dev/disk/by-id/nvme-Samsung_SSD_950_PRO_512GB_S2GMNCAGB32950E"; # NVMe ?
      sata0 = "/dev/disk/by-id/ata-WDC_WDS400T1R0A-68A4W0_21083X800070"; # SATA ?
      sata1 = "/dev/disk/by-id/ata-WDC_WDS400T1R0A-68A4W0_21083X800214"; # SATA ?
      sata2 = "/dev/disk/by-id/ata-WDC_WDS400T1R0A-68A4W0_21174H800355"; # SATA ?
      sata3 = "/dev/disk/by-id/ata-WDC_WDS400T1R0A-68A4W0_21174H800369"; # SATA ?
    };
  };

  # Network config.
  networking.interfaces.eno1.useDHCP = true;
}
