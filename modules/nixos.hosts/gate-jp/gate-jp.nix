{ self, inputs, ... }:
{
  my.hosts.gate-jp = {
    stateVersion = "25.05";

    nixosModule =
      { modulesPath, ... }:
      {
        imports = [
          "${modulesPath}/installer/scan/not-detected.nix"
          "${modulesPath}/profiles/qemu-guest.nix"

          inputs.nix-config-secrets.nixosModules.default
          inputs.nix-config-secrets.nixosModules.dns-qyrnl-dot-com
          inputs.nix-config-secrets.nixosModules.services-gatus
          inputs.nix-config-secrets.nixosModules.services-gatus-external-endpoints
          inputs.nix-config-secrets.nixosModules.services-gotify
          inputs.nix-config-secrets.nixosModules.services-hoopsnake-gate-jp
          inputs.nix-config-secrets.nixosModules.services-tailscale
          inputs.nix-config-secrets.nixosModules.users-delay

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
          self.nixosModules.selfhosted-dns-pieceofenglish-dot-fr
          self.nixosModules.selfhosted-dns-qyrnl-dot-com
          self.nixosModules.selfhosted-gatus
          self.nixosModules.selfhosted-gatus-endpoints
          self.nixosModules.selfhosted-gotify
          self.nixosModules.selfhosted-immich-public-proxy
          self.nixosModules.selfhosted-reverse-proxy-qyrnl-dot-com
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
            hostId = "60eec752";
            system = {
              disk = "/dev/sda";
              linode.swapDisk = "/dev/sdb";
              luksPasswordFile = "/tmp/root-disk-encryption.key";
            };
            zpool.root.reservation = "2GiB";
          };

          networking.tailscale.enableSsh = true;

          services = {
            dns = {
              "pieceofenglish.fr" = {
                enable = true;
                openFirewall = true;
                bindInterface = "eth0";
              };
              "qyrnl.com".enable = true;
            };

            gatus.enable = true;
            gotify.enable = true;
            immich-public-proxy.enable = true;

            reverse-proxy = {
              enable = true;
              "qyrnl.com" = {
                enable = true;
                # TODO: this should be read from the homelab config
                bindIP = "100.64.0.140";
              };
            };
          };

          users.delay.ssh.authorizeTailscaleInternalKey = true;
        };
      };

    users.delay.imports = with self.homeModules; [
      profile-hardware-server
      profile-ssh-keys-ring-3-tier
    ];
  };
}
