{pkgs, ...}: {
  imports = [
    ./fs.nix
  ];

  # Wayland, finally?
  modules.usrenv.compositor = "wayland";

  # Use Zellij for repository management.
  modules.usrenv.switcherApp = "zellij";

  # Boot configuration.
  boot.initrd.availableKernelModules = ["uhci_hcd" "ahci" "xhci_pci" "nvme" "usbhid" "sr_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = [];
  boot.extraModulePackages = [];

  # Be careful updating this.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Don't require password for sudo.
  security.sudo.wheelNeedsPassword = false;

  networking = {
    # TODO: probably needs to be adjusted.
    interfaces.ens160.useDHCP = true; # NAT adapter.
  };

  # Configure nixpkgs.
  # TODO: is this needed for anything? I'm already allowing unfree packages
  # on a per-case basis.
  nixpkgs.config.allowUnfree = true;
}
