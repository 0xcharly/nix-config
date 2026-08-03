{ self, inputs, ... }:
{
  my.hosts.gate-fr = {
    stateVersion = "25.05";

    nixosModule = {
      imports = [
        inputs.nix-config-secrets.nixosModules.default
        inputs.nix-config-secrets.nixosModules.services-hoopsnake-gate-fr
        inputs.nix-config-secrets.nixosModules.services-tailscale

        self.nixosModules.profile-fs-btrfs-server-linode
        self.nixosModules.profile-hardware-linode
        self.nixosModules.profile-hardware-server

        self.nixosModules.access-directory
        self.nixosModules.bootloader-grub
        self.nixosModules.initrd-hoopsnake
        self.nixosModules.nix
        self.nixosModules.nixpkgs
        self.nixosModules.programs-essentials
        self.nixosModules.programs-iotop
        self.nixosModules.programs-packages-common
        self.nixosModules.programs-sudo
        self.nixosModules.programs-terminfo
        self.nixosModules.prometheus-exporters-node
        self.nixosModules.selfhosted-dns-catchall
        self.nixosModules.selfhosted-dns-delay-dot-email
        self.nixosModules.selfhosted-dns-pieceofenglish-dot-fr
        self.nixosModules.selfhosted-dns-qyrnl-dot-com
        self.nixosModules.selfhosted-dns-xn--7ck8cva5eb-dot-com
        self.nixosModules.services-fail2ban
        self.nixosModules.services-openssh
        self.nixosModules.services-tailscale
        self.nixosModules.system-common
        self.nixosModules.system-linode
      ];

      # System config
      node = {
        fs.btrfs.root = {
          # by-id paths: /dev/sdX enumeration order is not stable across
          # boots, which intermittently broke swap activation.
          disk = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi-disk-0";
          luksPasswordFile = "/tmp/root-disk-encryption.key";
          swapSize = "2G";
        };

        networking.tailscale.enableSsh = true;

        services.dns = {
          catchall = {
            enable = true;
            openFirewall = true;
            bindInterface = "eth0";
          };
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
          "qyrnl.com" = {
            enable = true;
            blocking.enable = true;
          };
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
