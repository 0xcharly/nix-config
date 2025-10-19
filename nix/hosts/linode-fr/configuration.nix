{
  flake,
  inputs,
  hostName,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")

    inputs.nix-config-secrets.modules.nixos.blueprint
    inputs.nix-config-secrets.modules.nixos.nix-client-config
    inputs.nix-config-secrets.modules.nixos.services-tailscale
    inputs.nix-config-secrets.modules.nixos.users-delay

    flake.modules.common.nix-client-config
    flake.modules.common.nix-path
    flake.modules.common.nixpkgs-unfree
    flake.modules.common.nixpkgs-unstable
    flake.modules.common.overlays

    flake.modules.nixos.bootloader-grub
    flake.modules.nixos.fs-zfs-system-linode
    flake.modules.nixos.fs-zfs-zpool-root
    flake.modules.nixos.fs-zfs-zpool-root-data
    flake.modules.nixos.fs-zfs-zpool-root-home
    flake.modules.nixos.initrd-unlock-over-ssh
    flake.modules.nixos.initrd-tailscale
    flake.modules.nixos.nix-client-config
    flake.modules.nixos.overlays
    flake.modules.nixos.programs-iotop
    flake.modules.nixos.programs-packages-common
    flake.modules.nixos.programs-sudo
    flake.modules.nixos.programs-terminfo
    flake.modules.nixos.selfhosted-dns-pieceofenglish
    flake.modules.nixos.services-deploy-rs
    flake.modules.nixos.services-fail2ban
    flake.modules.nixos.services-openssh
    flake.modules.nixos.services-tailscale
    flake.modules.nixos.system-common
    flake.modules.nixos.system-linode
    flake.modules.nixos.users-delay
  ];

  # System config.
  node = {
    fs.zfs = {
      hostId = "0db85ca6";
      system = {
        disk = "/dev/sda";
        linode.swapDisk = "/dev/sdb";
        luksPasswordFile = "/tmp/root-disk-encryption.key";
      };
      zpool.root = {
        reservation = "2GiB";
        datadirs.pieceofenglish = {};
      };
    };

    services.dns."pieceofenglish.fr" = {
      enable = true;
      openFirewall = true;
      bindInterface = "eth0";
    };

    users.delay.ssh = {
      authorizeTailscaleInternalKey = true;
      authorizeTailscalePublicKey = true;
    };
  };

  networking = {
    inherit hostName;
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "25.05";

  time.timeZone = "Europe/Paris";
}
