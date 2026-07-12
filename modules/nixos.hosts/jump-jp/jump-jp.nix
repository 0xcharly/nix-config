{ self, inputs, ... }:
{
  my.hosts.jump-jp = {
    stateVersion = "25.11";

    nixosModule = {
      imports = [
        inputs.nix-config-secrets.nixosModules.default
        inputs.nix-config-secrets.nixosModules.services-hoopsnake-jump-jp
        inputs.nix-config-secrets.nixosModules.services-tailscale

        self.nixosModules.profile-hardware-linode
        self.nixosModules.profile-hardware-server

        self.nixosModules.access-directory
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
        self.nixosModules.services-fail2ban
        self.nixosModules.services-openssh
        self.nixosModules.services-tailscale
        self.nixosModules.system-common
        self.nixosModules.system-linode
      ];

      # System config
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

        networking.tailscale.enableSsh = true;
        users.delay.ssh.authorizeTailscaleInternalKey = true;
      };
    };

    users.delay.imports = with self.homeModules; [ profile-hardware-server ];
  };
}
