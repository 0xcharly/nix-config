{
  flake,
  inputs,
  hostName,
}: {modulesPath, ...}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")

    inputs.nix-config-secrets.modules.nixos.blueprint
    inputs.nix-config-secrets.modules.nixos.nix-client-config
    inputs.nix-config-secrets.modules.nixos.services-tailscale
    inputs.nix-config-secrets.modules.nixos.users-delay

    flake.modules.common.nix-client-config
    # flake.modules.common.nix-path
    flake.modules.common.nixpkgs-unfree
    flake.modules.common.nixpkgs-unstable
    flake.modules.common.overlays

    # flake.modules.nixos.fs-btrfs-system
    flake.modules.nixos.nix-client-config
    flake.modules.nixos.overlays
    flake.modules.nixos.programs-iotop
    flake.modules.nixos.programs-packages-common
    flake.modules.nixos.programs-sudo
    # flake.modules.nixos.programs-terminfo
    flake.modules.nixos.services-deploy-rs
    flake.modules.nixos.services-fail2ban
    flake.modules.nixos.services-openssh
    flake.modules.nixos.services-tailscale
    flake.modules.nixos.system-common
    flake.modules.nixos.users-delay
  ];

  # System config.
  node = {
    # fs.btrfs = {
    #   system = {
    #     disk = "/dev/sda";
    #     luksPasswordFile = "/tmp/root-disk-encryption.key";
    #     swapSize = "8G";
    #   };
    # };

    users.delay.ssh.authorizeTailscaleInternalKey = true;
  };

  networking = {
    inherit hostName;
  };

  nixpkgs.hostPlatform = "aarch64-linux";

  system.stateVersion = "25.05";
}
