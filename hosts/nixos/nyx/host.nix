{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./1password.nix
    ./audio.nix
    ./chromium.nix
    ./fs.nix
    ./llm.nix
    ./protonvpn.nix
    # This is currently doing nothing since the 24.11 version of OpenRGB (<1.0)
    # does not support the host's hardware, and the CPU cooler's RGB is already
    # disabled in BIOS.
    # TODO(25.05): consider re-enabling this service in 25.05 or later when
    # OpenRGB is supporting more hardware.
    # ./rgb.nix
    ./secrets.nix
    ./tailscale.nix
  ];

  # See comment in modules/nixos/module.nix.
  system.stateVersion = "24.11";

  # Wayland, finally?
  modules.usrenv.compositor = "wayland";

  # Roles.
  modules.system.roles.workstation = true;

  # Boot configuration.
  boot.initrd.availableKernelModules = ["ahci" "xhci_pci" "nvme" "usbhid" "sd_mod"];
  boot.initrd.kernelModules = ["amdgpu"];
  boot.kernelModules = ["kvm-amd"];
  boot.extraModulePackages = [];

  # Be careful updating this.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Don't require password for sudo.
  security.sudo.wheelNeedsPassword = false;

  networking = {
    interfaces.enp115s0.useDHCP = true;
  };

  # Automount removable devices (used by udiskie).
  services.udisks2.enable = true;

  services.xserver.videoDrivers = ["modesetting"];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      vaapiVdpau
      libvdpau-va-gl
      mangohud
      amdvlk
    ];
    extraPackages32 = with pkgs; [mangohud];
  };

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Configure nixpkgs.
  nixpkgs.config.allowUnfree = true;
}
