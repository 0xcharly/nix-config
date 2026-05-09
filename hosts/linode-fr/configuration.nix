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
    inputs.nix-config-secrets.nixosModules.services-tailscale
    inputs.nix-config-secrets.nixosModules.services-tailscale-initrd
    inputs.nix-config-secrets.nixosModules.users-delay

    flake.nixosModules.bootloader-grub
    flake.nixosModules.fs-zfs-system-linode
    flake.nixosModules.fs-zfs-zpool-root
    flake.nixosModules.fs-zfs-zpool-root-data
    flake.nixosModules.fs-zfs-zpool-root-home
    flake.nixosModules.initrd-tailscale
    flake.nixosModules.initrd-unlock-over-ssh
    flake.nixosModules.nix-config
    flake.nixosModules.nixpkgs
    flake.nixosModules.programs-essentials
    flake.nixosModules.programs-iotop
    flake.nixosModules.programs-packages-common
    flake.nixosModules.programs-sudo
    flake.nixosModules.programs-terminfo
    flake.nixosModules.prometheus-exporters-node
    flake.nixosModules.prometheus-exporters-zfs
    flake.nixosModules.selfhosted-dns-pieceofenglish-dot-fr
    flake.nixosModules.selfhosted-dns-qyrnl-dot-com
    flake.nixosModules.selfhosted-pieceofenglish
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
      hostId = "0db85ca6";
      system = {
        disk = "/dev/sda";
        linode.swapDisk = "/dev/sdb";
        luksPasswordFile = "/tmp/root-disk-encryption.key";
      };
      zpool.root.reservation = "2GiB";
    };

    services = {
      dns = {
        "pieceofenglish.fr" = {
          enable = true;
          openFirewall = true;
          bindInterface = "eth0";
        };
        "qyrnl.com".enable = true;
      };

      pieceofenglish = {
        enable = true;
        reverse-proxy = {
          enable = true;
          openFirewall = true;
          bindInterface = "eth0";
        };
      };
    };

    users.delay.ssh.authorizeTailscaleInternalKey = true;
  };

  networking = {
    inherit hostName;
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "25.05";

  time.timeZone = "Europe/Paris";
}
