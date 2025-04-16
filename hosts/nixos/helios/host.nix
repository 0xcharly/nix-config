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
    nas = true;
    noRgb = true;
    nas = true;
    protonvpn = true;
    tailscaleNode = true;
    workstation = true;
  };

  # Boot configuration.
  boot.initrd.availableKernelModules = ["ahci" "xhci_pci" "nvme" "usbhid" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = [];
  boot.extraModulePackages = [];

  # Be careful updating this. This must be compatible with the ZFS module.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network config.
  networking.interfaces.enp115s0.useDHCP = true;
}
