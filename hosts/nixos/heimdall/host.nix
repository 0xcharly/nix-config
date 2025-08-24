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
  node = {
    facts.tailscale = {
      tailscaleIPv4 = "100.85.79.53";
      tailscaleIPv6 = "fd7a:115c:a1e0::4036:4f35";
    };

    hardware = {
      cpu.vendor = "amd";
      gpu.vendor = "amd";
    };

    services = {
      atuin.enable = true;
      dns.enable = true;
      gatus.enable = true;
      golink.enable = true;
      gotify.enable = true;
      grafana.enable = true;
      immich-public-proxy.enable = true;
      miniflux.enable = true;
      prometheus = {
        server.enable = true;
        exporters.node.enable = true;
      };
      reverseProxy.enable = true;
      smtp.enable = true;
      taskchampion-sync-server.enable = true;
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
