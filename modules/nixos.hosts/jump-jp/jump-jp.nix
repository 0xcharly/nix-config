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
        self.nixosModules.selfhosted-mailserver
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

        services.mailserver.enable = true;

        users.delay.ssh.authorizeTailscaleInternalKey = true;
      };

      environment.persistence."/persist".directories = [
        "/var/vmail" # mail storage (SNM default)
        "/var/dkim" # DKIM keys — published DNS TXT records must keep matching
        "/var/sieve"
        "/var/lib/dovecot" # indices (indexDir = /var/lib/dovecot/indices) + FTS
        "/var/lib/postfix" # queue
        "/var/lib/rspamd"
        "/var/lib/redis-rspamd"
        "/var/lib/acme" # mail FQDN cert — Let's Encrypt rate limits
        # (knot-resolver cache deliberately not persisted — disposable.)
      ];

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
