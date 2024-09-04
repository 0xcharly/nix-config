{config, ...}: let
  inherit (config.modules.system.hosts) asl;
in {
  imports = [
    ./fs.nix
    ./mounts.nix
    ./vmware-guest.nix
  ];

  # Heasless system à la WSL.
  modules.usrenv.compositor = "headless";

  # Disable the default module and import our override that works on aarch64.
  # NOTE: the PR has been merge to the unstable branch and should be available
  # in 24.11: https://github.com/NixOS/nixpkgs/pull/326395.
  # TODO: use builtin module after switching to 24.11.
  disabledModules = ["virtualisation/vmware-guest.nix"];

  # Setup qemu so we can run x86_64 binaries.
  boot.binfmt.emulatedSystems = ["x86_64-linux"];

  # This works through our custom module imported above.
  virtualisation.vmware.guest.enable = true;

  # Boot configuration.
  boot.initrd.availableKernelModules = ["uhci_hcd" "ahci" "xhci_pci" "nvme" "usbhid" "sr_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = [];
  boot.extraModulePackages = [];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # VMware, Parallels both only support this being 0 otherwise you see
  # "error switching console mode" on boot.
  boot.loader.systemd-boot.consoleMode = "0";

  # Don't require password for sudo.
  security.sudo.wheelNeedsPassword = false;

  networking = {
    hostName = "asl";
    # NAT adapter interface names on M1, M3.
    interfaces.ens160 = {
      useDHCP = false;
      ipv4.addresses = [{inherit (asl.networking) address prefixLength;}];
    };
    inherit (asl.networking) defaultGateway nameservers;

    # Disable the firewall since we're in a VM and we want to make it
    # easy to visit stuff in here. We only use NAT networking anyways.
    firewall.enable = false;
  };

  # Lots of stuff that uses aarch64 that claims doesn't work, but actually works.
  nixpkgs.config.allowUnsupportedSystem = true;
}
