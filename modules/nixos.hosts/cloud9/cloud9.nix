{ self, inputs, ... }:
{
  my.hosts.cloud9 = {
    stateVersion = "25.11";

    nixosModule =
      { modulesPath, ... }:
      {
        imports = [
          "${modulesPath}/installer/scan/not-detected.nix"
          "${modulesPath}/profiles/qemu-guest.nix"

          inputs.nix-config-secrets.nixosModules.default
          inputs.nix-config-secrets.nixosModules.services-hoopsnake-cloud9
          inputs.nix-config-secrets.nixosModules.services-tailscale
          inputs.nix-config-secrets.nixosModules.users-delay

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
          self.nixosModules.users-delay
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
