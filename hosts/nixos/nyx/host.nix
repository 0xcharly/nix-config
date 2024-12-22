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
    ./fs.nix
    ./rgb.nix
  ];

  # See comment in modules/nixos/module.nix.
  system.stateVersion = "24.11";

  # Wayland, finally?
  modules.usrenv.compositor = "wayland";

  # Use Zellij for repository management.
  modules.usrenv.switcherApp = "zellij";

  # Boot configuration.
  boot.initrd.availableKernelModules = ["ahci" "xhci_pci" "nvme" "usbhid" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["amdgpu" "kvm-amd"];
  boot.kernelParams = ["amdgpu.admlevel=1"];
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

  services.xserver.videoDrivers = ["amdgpu" "modesetting"];
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
  # TODO: is this needed for anything? I'm already allowing unfree packages
  # on a per-case basis.
  nixpkgs.config.allowUnfree = true;
}
