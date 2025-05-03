{
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # See comment in modules/nixos/module.nix.
  system.stateVersion = "24.11";

  # Headless server.
  modules.usrenv.compositor = "headless";

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

  # Boot configuration.
  boot.initrd.availableKernelModules = ["ahci" "xhci_pci" "nvme" "usbhid" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = [];
  boot.extraModulePackages = [];

  # IMPORTANT NOTE: Carefully check the latest kernel version that is compatible
  # with the ZFS version in use.
  # Compatible kernel versions are listed on the OpenZFS release page. Check
  # which ZFS version is in use for the current stable channel.
  # The current stable channel is 24.11, which uses ZFS 2.2.7, and is compatible
  # with 4.18 - 6.12 kernels.
  # https://discourse.nixos.org/t/zfs-latestcompatiblelinuxpackages-is-deprecated/52540
  # https://github.com/openzfs/zfs/releases
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  # Use the systemd-boot EFI boot loader.
  boot.loader.grub.enable = true;

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
