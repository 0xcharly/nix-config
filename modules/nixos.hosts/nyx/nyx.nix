{ self, inputs, ... }:
{
  my.hosts.nyx = {
    stateVersion = "25.05";

    nixosModule =
      { modulesPath, ... }:
      {
        imports = [
          "${modulesPath}/installer/scan/not-detected.nix"

          inputs.nix-config-colorscheme.nixosModules.console

          inputs.nix-config-secrets.nixosModules.default
          inputs.nix-config-secrets.nixosModules.jptax-fa5003-inputs
          inputs.nix-config-secrets.nixosModules.services-tailscale
          inputs.nix-config-secrets.nixosModules.ssh-keys-ring-0-tier
          inputs.nix-config-secrets.nixosModules.users-delay

          self.nixosModules.profile-hardware-workstation

          self.nixosModules.bootloader-systemd-boot
          self.nixosModules.fs-zfs-common
          self.nixosModules.fs-zfs-system-base
          self.nixosModules.fs-zfs-system
          self.nixosModules.fs-zfs-zpool-root
          self.nixosModules.fs-zfs-zpool-root-home
          self.nixosModules.hardware-cpu-amd
          self.nixosModules.hardware-gpu-amd
          self.nixosModules.hardware-wake-on-lan
          self.nixosModules.networking-common
          self.nixosModules.networking-resolved
          self.nixosModules.nix
          self.nixosModules.nix-build-aarch64
          self.nixosModules.nixpkgs
          self.nixosModules.programs-apdbctl
          self.nixosModules.programs-essentials
          self.nixosModules.programs-gnome-calendar
          self.nixosModules.programs-greetd
          self.nixosModules.programs-greetd-autologin
          self.nixosModules.programs-iotop
          self.nixosModules.programs-packages-common
          self.nixosModules.programs-secrets
          self.nixosModules.programs-steam
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
          self.nixosModules.services-zmk-studio
          self.nixosModules.system-common
          self.nixosModules.system-fonts
          self.nixosModules.users-delay
        ];

        # System config
        node = {
          fs.zfs = {
            hostId = "0a52fab4";
            system = {
              disk = "/dev/disk/by-id/nvme-CT4000T700SSD3_2340E87BB2E0";
              luksPasswordFile = "/tmp/root-disk-encryption.key";
              swapSize = "72G"; # Size of RAM + square root of RAM for hibernate
            };
          };

          networking.wakeOnLan.interface = "enp115s0";
          users.delay.ssh.authorizeTailscaleInternalKey = true;
        };

        boot.initrd.availableKernelModules = [
          "ahci"
          "nvme"
          "sd_mod"
          "usbhid"
          "xhci_pci"
        ];

        networking.interfaces.enp115s0.useDHCP = true;
      };

    users.delay = {
      imports = with self.homeModules; [
        profile-hardware-workstation
        profile-ssh-keys-ring-0-tier
      ];

      node = {
        wayland = {
          hyprland.monitor = "DP-3, 6016x3384@60.00Hz, 0x0, 2.00";

          display.logicalResolution = {
            width = 3008;
            height = 1692;
          };

          arcshell.wallpaper.animate = true;
        };
      };
    };
  };
}
