{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.modules.system.roles.nas.enable {
  # See comment in modules/nixos/module.nix.
  system.stateVersion = "24.11";

  # Headless server.
  modules.usrenv.compositor = "headless";

  # Configure nixpkgs.
  nixpkgs.config.allowUnfree = true;

  # Don't require password for sudo.
  security.sudo.wheelNeedsPassword = false;

  # Boot configuration.
  boot.initrd.availableKernelModules = ["ahci" "xhci_pci" "nvme" "usbhid" "sd_mod"];

  # IMPORTANT NOTE: Carefully check the latest kernel version that is compatible
  # with the ZFS version in use.
  # Compatible kernel versions are listed on the OpenZFS release page. Check
  # which ZFS version is in use for the current stable channel.
  # The current stable channel is 24.11, which uses ZFS 2.2.7, and is compatible
  # with 4.18 - 6.12 kernels.
  # https://discourse.nixos.org/t/zfs-latestcompatiblelinuxpackages-is-deprecated/52540
  # https://github.com/openzfs/zfs/releases
  boot.kernelPackages = pkgs.linuxPackages_6_12;
}
