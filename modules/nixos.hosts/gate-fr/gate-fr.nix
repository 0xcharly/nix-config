{ self, inputs, ... }:
{
  my.hosts.gate-fr = {
    stateVersion = "25.05";

    nixosModule = {
      imports = [
        inputs.nix-config-secrets.nixosModules.default
        inputs.nix-config-secrets.nixosModules.services-hoopsnake-gate-fr
        inputs.nix-config-secrets.nixosModules.services-tailscale
        inputs.nix-config-secrets.nixosModules.users-delay

        self.nixosModules.profile-hardware-linode
        self.nixosModules.profile-hardware-server

        self.nixosModules.bootloader-grub
        self.nixosModules.fs-zfs-common
        self.nixosModules.fs-zfs-system-base
        self.nixosModules.fs-zfs-system-linode
        self.nixosModules.fs-zfs-zpool-root
        self.nixosModules.fs-zfs-zpool-root-data
        self.nixosModules.fs-zfs-zpool-root-home
        self.nixosModules.initrd-hoopsnake
        self.nixosModules.nix
        self.nixosModules.nixpkgs
        self.nixosModules.programs-essentials
        self.nixosModules.programs-iotop
        self.nixosModules.programs-packages-common
        self.nixosModules.programs-sudo
        self.nixosModules.programs-terminfo
        self.nixosModules.prometheus-exporters-node
        self.nixosModules.prometheus-exporters-zfs
        self.nixosModules.selfhosted-dns-delay-dot-email
        self.nixosModules.selfhosted-dns-pieceofenglish-dot-fr
        self.nixosModules.selfhosted-dns-qyrnl-dot-com
        self.nixosModules.selfhosted-dns-xn--7ck8cva5eb-dot-com
        self.nixosModules.services-fail2ban
        self.nixosModules.services-openssh
        self.nixosModules.services-tailscale
        self.nixosModules.system-common
        self.nixosModules.system-linode
        self.nixosModules.users-delay
      ];

      # System config
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

        networking.tailscale.enableSsh = true;

        services.dns = {
          "delay.email" = {
            enable = true;
            openFirewall = true;
            bindInterface = "eth0";
          };
          "pieceofenglish.fr" = {
            enable = true;
            openFirewall = true;
            bindInterface = "eth0";
          };
          "qyrnl.com".enable = true;
          "xn--7ck8cva5eb.com" = {
            enable = true;
            openFirewall = true;
            bindInterface = "eth0";
          };
        };

        users.delay.ssh.authorizeTailscaleInternalKey = true;
      };

      time.timeZone = "Europe/Paris";
    };

    users.delay.imports = with self.homeModules; [ profile-hardware-server ];
  };
}
