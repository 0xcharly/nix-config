{
  config,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # System config.
  modules.system = {
    healthchecks.ping = {
      enable = true;
      keyFile = config.age.secrets."healthchecks/ping-skullkid".path;
    };
    security.accessTier = "trusted";
    networking.tailscaleNode = true;
    roles.nixos.intelThunderbolt = true;
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
