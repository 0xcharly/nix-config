{
  config-manager,
  pkgs,
  ...
}: {
  imports = with config-manager; [
    system.vm-disks
    system.vmware-guest
    system.nixos-compositor-common
    system.nixos-x11
    system.nixos-wayland
  ];

  # Disable the default module and import our override that works on aarch64.
  # TODO: revert when https://github.com/NixOS/nixpkgs/pull/326395 is stable.
  disabledModules = ["virtualisation/vmware-guest.nix"];

  # Wayland crashes on VMWare Fusion.
  settings.compositor = "x11";

  # Setup qemu so we can run x86_64 binaries
  boot.binfmt.emulatedSystems = ["x86_64-linux"];

  # This works through our custom module imported above
  virtualisation.vmware.guest.enable = true;

  # This is needed for the vmware user tools clipboard to work.
  environment.systemPackages = [pkgs.gtkmm3];

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
    # Define your hostname.
    hostName = "vm-aarch64";

    # Interface names on M1, M3.
    interfaces.ens160.useDHCP = true; # NAT adapter.

    # Disable the firewall since we're in a VM and we want to make it
    # easy to visit stuff in here. We only use NAT networking anyways.
    firewall.enable = false;
  };

  # Configure nixpkgs.
  nixpkgs = {
    hostPlatform = "aarch64-linux";

    config = {
      # TODO: is this needed for anything? I'm already allowing unfree packages
      # on a per-case basis.
      allowUnfree = true;
      # Lots of stuff that uses aarch64 that claims doesn't work, but actually works.
      allowUnsupportedSystem = true;
    };
  };

  # Share our host filesystem.
  fileSystems."/host" = {
    fsType = "fuse./run/current-system/sw/bin/vmhgfs-fuse";
    device = ".host:/";
    options = [
      "umask=22"
      "uid=1000"
      "gid=1000"
      "allow_other"
      "auto_unmount"
      "defaults"
    ];
  };
}
