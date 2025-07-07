{
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./fs.nix
  ];

  # See comment in modules/nixos/module.nix.
  system.stateVersion = "25.05";

  # No graphical environment.
  modules.usrenv.compositor = "headless";

  # System config.
  modules.system = {
    security.accessTier = "trusted";
    monitoring.statusServer = true;
    networking = {
      dnsServer = true;
      tailscaleNode = true;
    };
    roles.nixos = {
      amdCpu = true;
      protonvpn = true;
    };
  };

  # Boot configuration.
  boot = {
    initrd = {
      availableKernelModules = ["ahci" "xhci_pci" "nvme" "usbhid" "sd_mod"];
      supportedFilesystems = ["btrfs"];
    };

    kernelPackages = pkgs.linuxPackages_latest; # Be careful updating this.

    # Use the systemd-boot EFI boot loader.
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  # Network config.
  networking.interfaces.enp15s0.useDHCP = true;
}
