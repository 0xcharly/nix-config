{
  config,
  lib,
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

  # NOTE: temporary kludge until Heimdall is migrated to Blueprint.
  services = {
    caddy.virtualHosts = lib.mkIf config.node.services.reverseProxy.enable {
      "git.qyrnl.com".extraConfig = ''
        import ts_host
        reverse_proxy bowmore.qyrnl.com:3917
      '';
    };

    gatus.settings.endpoints = [
      (lib.fn.mkHttpServiceEndpoint "Forgejo" "git.qyrnl.com")
    ];
  };

  # System config.
  node = {
    facts.tailscale = {
      # TODO: move these definitions to facts.
      tailscaleIPv4 = "100.85.79.53";
      tailscaleIPv6 = "fd7a:115c:a1e0::4036:4f35";
    };

    hardware = {
      cpu.vendor = "amd";
      gpu.vendor = "amd";
    };

    services = {
      atuin.enable = false; # 2025-11-03: migrated to bowmore.
      dns.enable = true;
      gatus.enable = true;
      golink.enable = true;
      gotify.enable = true;
      grafana.enable = true;
      immich-public-proxy.enable = true;
      miniflux.enable = false; # 2025-11-03: migrated to bowmore.
      prometheus = {
        server.enable = true;
        exporters.node.enable = true;
      };
      reverseProxy.enable = true;
      smtp.enable = false; # 2025-11-03: migrated to bowmore.
      taskchampion-sync-server.enable = false; # 2025-11-03: Disabled because unused. Will decommission.
      vaultwarden.enable = false; # 2025-11-03: migrated to bowmore.
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
