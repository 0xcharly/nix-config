{
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./1password.nix
    ./android.nix
    ./audio.nix
    ./fs.nix
    ./gdm.nix
    ./llm.nix
    ./steam.nix
  ];

  # See comment in modules/nixos/module.nix.
  system.stateVersion = "24.11";

  # Wayland, finally?
  modules.usrenv.compositor = "wayland";

  # System config.
  modules.system = {
    security.accessTier = "highly-privileged";
    networking.tailscaleNode = true;
    roles.nixos = {
      amdCpu = true;
      amdGpu = true;
      noRgb = true;
      protonvpn = true;
      workstation = true;
    };
  };

  # Boot configuration.
  boot = {
    initrd = {
      availableKernelModules = ["ahci" "xhci_pci" "nvme" "usbhid" "sd_mod"];
      kernelModules = [];
    };
    kernelModules = [];
    extraModulePackages = [];

    kernelPackages = pkgs.linuxPackages_latest; # Be careful updating this.

    # Use the systemd-boot EFI boot loader.
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  # Network config.
  networking.interfaces.enp115s0.useDHCP = true;
}
