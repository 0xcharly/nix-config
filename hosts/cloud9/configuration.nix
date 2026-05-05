{
  flake,
  inputs,
  hostName,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")

    inputs.nix-config-secrets.nixosModules.default
    inputs.nix-config-secrets.nixosModules.nix-client-config
    inputs.nix-config-secrets.nixosModules.services-tailscale
    inputs.nix-config-secrets.nixosModules.services-tailscale-initrd
    inputs.nix-config-secrets.nixosModules.users-delay

    flake.modules.common.nix-client-config
    flake.modules.common.nix-path
    flake.modules.common.nixpkgs-unfree
    flake.modules.common.nixpkgs-unstable
    flake.modules.common.overlays

    flake.nixosModules.bootloader-grub
    flake.nixosModules.fs-zfs-system-linode
    flake.nixosModules.fs-zfs-zpool-root
    flake.nixosModules.fs-zfs-zpool-root-data
    flake.nixosModules.fs-zfs-zpool-root-home
    flake.nixosModules.initrd-unlock-over-ssh
    flake.nixosModules.initrd-tailscale
    flake.nixosModules.nix-client-config
    flake.nixosModules.overlays
    flake.nixosModules.programs-essentials
    flake.nixosModules.programs-iotop
    flake.nixosModules.programs-packages-common
    flake.nixosModules.programs-sudo
    flake.nixosModules.programs-terminfo
    flake.nixosModules.prometheus-exporters-node
    flake.nixosModules.prometheus-exporters-zfs
    flake.nixosModules.services-deploy-rs
    flake.nixosModules.services-fail2ban
    flake.nixosModules.services-openssh
    flake.nixosModules.services-tailscale
    flake.nixosModules.system-common
    flake.nixosModules.system-linode
    flake.nixosModules.users-delay
  ];

  # System config.
  node = {
    fs.zfs = {
      hostId = "df18314a";
      system = {
        disk = "/dev/sda";
        linode.swapDisk = "/dev/sdb";
        luksPasswordFile = "/tmp/root-disk-encryption.key";
      };
      zpool.root.reservation = "2GiB";
    };

    users.delay.ssh.authorizeTailscaleInternalKey = true;
  };

  networking = {
    inherit hostName;
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "25.11";
}
