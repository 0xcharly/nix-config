{modulesPath, ...}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Roles.
  modules.system.roles.nixos = {
    amdCpu = true;
    noRgb = true;
    tailscaleNode = true;
  };

  modules.system.roles.nas = {
    enable = true;
    hostId = "af9964d6";
    drives = {
      nvme0 = "/dev/disk/by-id/nvme-Samsung_SSD_980_500GB_S78GNL0XC30952W"; # Front NVMe
      nvme1 = "/dev/disk/by-id/nvme-Samsung_SSD_980_500GB_S78GNL0XC30991Y"; # Back NVMe
      sata0 = "/dev/disk/by-id/ata-ST24000NT002-3N1101_ZYD2E1FW"; # SATA 1 / Blue
      sata1 = "/dev/disk/by-id/ata-ST24000NT002-3N1101_ZYD20R4R"; # SATA 2 / Red
      sata2 = "/dev/disk/by-id/ata-ST24000NT002-3N1101_ZYD254N6"; # SATA 3 / Yellow
      sata3 = "/dev/disk/by-id/ata-ST24000NT002-3N1101_ZYD160A1"; # SATA 4 / Green
    };
  };

  # Network config.
  networking = {
    interfaces.enp11s0.ipv4.addresses = [
      {
        address = "192.168.1.230";
        prefixLength = 24;
      }
    ];
    defaultGateway = "192.168.1.1";
    nameservers = ["1.1.1.1" "8.8.8.8"];
  };
}
