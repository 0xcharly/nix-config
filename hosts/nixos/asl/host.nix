{pkgs, ...}: {
  imports = [
    ./fs.nix
    ./mounts.nix
  ];

  # Headless system à la WSL.
  modules.usrenv.compositor = "headless";

  # Setup qemu so we can run x86_64 binaries.
  boot.binfmt.emulatedSystems = ["x86_64-linux"];

  # This works through our custom module imported above.
  virtualisation.vmware.guest.enable = true;

  # Boot configuration.
  boot = {
    initrd = {
      availableKernelModules = ["uhci_hcd" "ahci" "xhci_pci" "nvme" "usbhid" "sr_mod"];
      kernelModules = [];
    };
    kernelModules = [];
    extraModulePackages = [];

    kernelPackages = pkgs.linuxPackages_latest; # Be careful updating this.

    # Use the systemd-boot EFI boot loader.
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;

      # VMware, Parallels both only support this being 0 otherwise you see
      # "error switching console mode" on boot.
      systemd-boot.consoleMode = "0";
    };
  };

  # Don't require password for sudo.
  security.sudo.wheelNeedsPassword = false;

  networking = {
    hostName = "asl";
    # NAT adapter interface names on M1, M3.
    interfaces.ens160.ipv4.addresses = [
      {
        address = "192.168.70.3";
        prefixLength = 24;
      }
    ];
    defaultGateway = "192.168.70.2";
    nameservers = ["192.168.70.2"];

    # Disable the firewall since we're in a VM and we want to make it
    # easy to visit stuff in here. We only use NAT networking anyways.
    firewall.enable = false;
  };

  # Lots of stuff that uses aarch64 that claims doesn't work, but actually works.
  nixpkgs.config.allowUnsupportedSystem = true;
}
