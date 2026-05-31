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
          inputs.nix-config-secrets.nixosModules.users-delay

          self.nixosModules.profile-hardware-workstation

          self.nixosModules.bootloader-systemd-boot
          self.nixosModules.fs-zfs-common
          self.nixosModules.fs-zfs-system
          self.nixosModules.fs-zfs-system-base
          self.nixosModules.fs-zfs-zpool-root
          self.nixosModules.fs-zfs-zpool-root-home
          self.nixosModules.hardware-cpu-amd
          self.nixosModules.hardware-gpu-amd
          self.nixosModules.networking-bluetooth
          self.nixosModules.networking-wireless
          self.nixosModules.nix
          self.nixosModules.nixpkgs
          self.nixosModules.programs-essentials
          self.nixosModules.programs-greetd
          self.nixosModules.programs-greetd-autologin
          self.nixosModules.programs-iotop
          self.nixosModules.programs-packages-common
          self.nixosModules.programs-secrets
          self.nixosModules.programs-sudo
          self.nixosModules.programs-terminfo
          self.nixosModules.prometheus-exporters-node
          self.nixosModules.prometheus-exporters-zfs
          self.nixosModules.services-adb
          self.nixosModules.services-deploy-rs
          self.nixosModules.services-fail2ban
          self.nixosModules.services-openssh
          self.nixosModules.services-pipewire
          self.nixosModules.services-removable-devices
          self.nixosModules.services-tailscale
          self.nixosModules.system-common
          self.nixosModules.system-fonts
          self.nixosModules.users-delay
        ];

        # System config
        node = {
          fs.zfs = {
            hostId = "be2d9ac1";
            system = {
              disk = "/dev/disk/by-id/nvme-KINGSTON_OM8TAP41024K1-A00_50026B7383D8FFFF";
              luksPasswordFile = "/tmp/root-disk-encryption.key";
              swapSize = "16G";
            };
          };

          networking = {
            bluetooth = {
              powerOnBoot = true;
              enableFastConnectable = true;
            };
            tailscale.acceptRoutes = true;
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
          wlp194s0.useDHCP = true;
        };
      };

    users.delay = {
      imports = with self.homeModules; [
        profile-hardware-wireless
        profile-hardware-workstation
        profile-ssh-keys-ring-0-tier
      ];

      node = {
        wayland = {
          # https://wiki.hypr.land/0.41.2/Configuring/Monitors/#rotating
          #
          # | Transform              | x |
          # + ---------------------- + - +
          # | normal (no transforms) | 0 |
          # | 90 degrees             | 1 |
          # | 180 degrees            | 2 |
          # | 270 degrees            | 3 |
          # | flipped                | 4 |
          # | flipped + 90 degrees   | 5 |
          # | flipped + 180 degrees  | 6 |
          # | flipped + 270 degrees  | 7 |
          #
          hyprland.monitor = "DP-1, 3840x2160@59.997Hz, 0x0, 1.25, transform, 1";

          display.logicalResolution = {
            width = 3072;
            height = 1728;
          };

          idle = {
            screenlock.enable = true;
            suspend.enable = false;
          };
        };
      };
    };
  };
}
