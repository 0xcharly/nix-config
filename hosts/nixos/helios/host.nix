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
    intelGpu = true;
    noRgb = true;
    protonvpn = true;
    tailscaleNode = true;
    workstation = true;
  };

  modules.system.roles.nas = {
    enable = true;
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
  networking.interfaces.enp15s0.useDHCP = true;
}
