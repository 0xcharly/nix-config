{ self, inputs, ... }:
{
  my.hosts.node-skl = {
    stateVersion = "25.05";

    nixosModule =
      { modulesPath, ... }:
      {
        imports = [
          "${modulesPath}/installer/scan/not-detected.nix"

          self.nixosModules.colors-console

          inputs.nix-config-secrets.nixosModules.default
          inputs.nix-config-secrets.nixosModules.services-hoopsnake-node-skl
          inputs.nix-config-secrets.nixosModules.services-tailscale
          inputs.nix-config-secrets.nixosModules.users-delay

          self.nixosModules.profile-hardware-server

          self.nixosModules.bootloader-systemd-boot
          self.nixosModules.fs-zfs-common
          self.nixosModules.fs-zfs-system
          self.nixosModules.fs-zfs-system-base
          self.nixosModules.fs-zfs-zpool-root
          self.nixosModules.fs-zfs-zpool-root-home
          self.nixosModules.hardware-cpu-intel
          self.nixosModules.hardware-gpu-intel
          self.nixosModules.initrd-hoopsnake
          self.nixosModules.nix
          self.nixosModules.nixpkgs
          self.nixosModules.programs-essentials
          self.nixosModules.programs-iotop
          self.nixosModules.programs-packages-common
          self.nixosModules.programs-secrets
          self.nixosModules.programs-sudo
          self.nixosModules.programs-terminfo
          self.nixosModules.prometheus-exporters-node
          self.nixosModules.prometheus-exporters-zfs
          self.nixosModules.services-fail2ban
          self.nixosModules.services-openssh
          self.nixosModules.services-tailscale
          self.nixosModules.system-common
          self.nixosModules.users-delay
        ];

        # System config
        node = {
          boot.initrd.hoopsnake.kernelModules = [ "e1000e" ];

          fs.zfs = {
            hostId = "be2d9ac1";
            system = {
              disk = "/dev/disk/by-id/nvme-Samsung_SSD_950_PRO_512GB_S2GMNCAGB32083T";
              luksPasswordFile = "/tmp/root-disk-encryption.key";
              swapSize = "16G";
            };
          };

          networking.tailscale.enableSsh = true;
          users.delay.ssh.authorizeTailscaleInternalKey = true;
        };

        boot.initrd.availableKernelModules = [
          "ahci"
          "nvme"
          "sd_mod"
          "usbhid"
          "xhci_pci"
        ];

        networking.interfaces.eno1.useDHCP = true;
      };

    users.delay.imports = with self.homeModules; [ profile-hardware-server ];
  };
}
