{
  config,
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
  node = {
    facts.tailscale = {
      tailscaleIPv4 = "100.85.79.53";
      tailscaleIPv6 = "fd7a:115c:a1e0::4036:4f35";
    };

    hardware = {
      cpu.vendor = "amd";
      gpu.vendor = "amd";
    };

    healthchecks.ping = {
      enable = true;
      keyFile = config.age.secrets."healthchecks/ping-heimdall".path;
    };

    services = {
      atuin.enable = true;
      dns.enable = true;
      golink.enable = true;
      gotify.enable = true;
      healthchecks.enable = true;
      immich-public-proxy.enable = true;
      miniflux.enable = true;
      reverseProxy.enable = true;
      smtp.enable = true;
      taskchampion-sync-server.enable = true;
      uptime-kuma.enable = true;
      vaultwarden.enable = true;
    };
  };

  modules.system = {
    security.accessTier = "trusted";
    networking.tailscaleNode = true;
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
  networking.interfaces.enp196s0.useDHCP = true;
}
