{ self, inputs, ... }:
{
  flake.nixosModules.skl-host-nixos =
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
        self.nixosModules.fs-zfs-system-base
        self.nixosModules.fs-zfs-system
        self.nixosModules.fs-zfs-zpool-root
        self.nixosModules.fs-zfs-zpool-root-home
        self.nixosModules.hardware-cpu-intel
        self.nixosModules.hardware-gpu-intel
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

      # System config.
      node = {
        fs.zfs = {
          hostId = "be2d9ac1";
          system = {
            disk = "/dev/disk/by-id/nvme-Samsung_SSD_950_PRO_512GB_S2GMNCAGB32083T";
            luksPasswordFile = "/tmp/root-disk-encryption.key";
            swapSize = "20G"; # Size of RAM + square root of RAM for hibernate
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

      networking = {
        hostName = "skl";
        domain = "qyrnl.com";
        interfaces = {
          eno1.useDHCP = true;
          wlp3s0.useDHCP = true;
        };
      };

      nixpkgs.hostPlatform = "x86_64-linux";

      system.stateVersion = "25.05";
    };
}
