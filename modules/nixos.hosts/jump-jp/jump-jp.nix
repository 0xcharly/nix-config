{ self, inputs, ... }:
{
  my.hosts.jump-jp = {
    stateVersion = "25.11";

    nixosModule = {
      imports = [
        inputs.nix-config-secrets.nixosModules.default
        inputs.nix-config-secrets.nixosModules.services-gatus-external-endpoints
        inputs.nix-config-secrets.nixosModules.services-hoopsnake-jump-jp
        inputs.nix-config-secrets.nixosModules.services-mailserver
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
        self.nixosModules.selfhosted-mailserver
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
            # by-id paths: /dev/sdX enumeration order is not stable across
            # boots, which intermittently broke swap activation.
            disk = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi-disk-0";
            linode.swapDisk = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi-disk-1";
            luksPasswordFile = "/tmp/root-disk-encryption.key";
          };
          zpool.root.reservation = "2GiB";
        };

        networking.tailscale.enableSsh = true;

        services.mailserver.enable = true;

        users.delay.ssh.authorizeTailscaleInternalKey = true;
      };

      # Jump-only relay hop for the site-jp -> site-fr ZFS replication
      # (syncoid --sshoption ProxyJump=syncoid@jump-jp). The user itself
      # comes from access-directory; here it only needs the replication
      # key and TCP forwarding — never a shell.
      users.users.syncoid = {
        shell = "/run/current-system/sw/bin/nologin";
        openssh.authorizedKeys.keys = [
          # keys/zfs_replication_ed25519 — same key authorized on site-fr.
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIf1BY82EBfuIPmqzPhA0SXNRQ9z7zdCzE99TiqdjWmg"
        ];
      };

      services.openssh.extraConfig = ''
        Match User syncoid
          AllowTcpForwarding yes
          PermitTTY no
          ForceCommand /run/current-system/sw/bin/nologin
      '';
    };

    users.delay.imports = with self.homeModules; [ profile-hardware-server ];
  };
}
