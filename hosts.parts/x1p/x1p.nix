{ self, inputs, ... }:
{
  my.hosts.x1p = {
    stateVersion = "25.11";

    nixosModule =
      { modulesPath, ... }:
      {
        imports = [
          "${modulesPath}/installer/scan/not-detected.nix"

          inputs.nix-config-colorscheme.nixosModules.console

          inputs.nix-config-secrets.nixosModules.default
          inputs.nix-config-secrets.nixosModules.services-tailscale
          inputs.nix-config-secrets.nixosModules.services-tailscale-initrd
          inputs.nix-config-secrets.nixosModules.users-delay

          self.nixosModules.bootloader-systemd-boot
          self.nixosModules.fs-zfs-common
          self.nixosModules.fs-zfs-system-base
          self.nixosModules.fs-zfs-system
          self.nixosModules.fs-zfs-zpool-root
          self.nixosModules.fs-zfs-zpool-root-data
          self.nixosModules.fs-zfs-zpool-root-home
          self.nixosModules.hardware-cpu-intel
          self.nixosModules.hardware-gpu-intel
          self.nixosModules.initrd-tailscale
          self.nixosModules.initrd-unlock-over-ssh
          self.nixosModules.nix
          self.nixosModules.nix-build-aarch64
          self.nixosModules.nixpkgs
          self.nixosModules.programs-essentials
          self.nixosModules.programs-iotop
          self.nixosModules.programs-packages-common
          self.nixosModules.programs-sudo
          self.nixosModules.programs-terminfo
          self.nixosModules.prometheus-exporters-node
          self.nixosModules.prometheus-exporters-zfs
          self.nixosModules.services-deploy-rs
          self.nixosModules.services-fail2ban
          self.nixosModules.services-openssh
          self.nixosModules.services-tailscale
          self.nixosModules.system-common
          self.nixosModules.users-delay
        ];

        # System config.
        node = {
          boot.initrd.ssh-unlock.kernelModules = [ "r8169" ];

          fs.zfs = {
            hostId = "be2d9ac1";
            system = {
              disk = "/dev/disk/by-id/nvme-KINGSTON_OM8TAP41024K1-A00_50026B7383D8FFFF";
              luksPasswordFile = "/tmp/root-disk-encryption.key";
              swapSize = "16G";
            };
          };

          users.delay.ssh.authorizeTailscaleInternalKey = true;
        };

        boot.initrd.availableKernelModules = [
          "ahci"
          "nvme"
          "sd_mod"
          "usbhid"
          "xhci_pci"
        ];

        networking.interfaces = {
          enp195s0.useDHCP = true;
          enp196s0.useDHCP = true;
        };
      };

    users.delay.imports = [ self.homeModules.profile-hardware-server ];
  };
}
