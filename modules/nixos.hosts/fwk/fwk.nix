{ self, inputs, ... }:
{
  my.hosts.fwk = {
    stateVersion = "25.05";

    nixosModule =
      { modulesPath, pkgs, ... }:
      {
        imports = [
          "${modulesPath}/installer/scan/not-detected.nix"

          inputs.nix-config-colorscheme.nixosModules.console

          inputs.nix-config-secrets.nixosModules.default
          inputs.nix-config-secrets.nixosModules.jptax-fa5003-inputs
          inputs.nix-config-secrets.nixosModules.services-tailscale
          inputs.nix-config-secrets.nixosModules.ssh-keys-ring-0-tier
          inputs.nix-config-secrets.nixosModules.users-delay

          self.nixosModules.profile-hardware-laptop

          self.nixosModules.bootloader-systemd-boot
          self.nixosModules.fs-zfs-common
          self.nixosModules.fs-zfs-system-base
          self.nixosModules.fs-zfs-system
          self.nixosModules.fs-zfs-zpool-root
          self.nixosModules.fs-zfs-zpool-root-home
          self.nixosModules.hardware-cpu-amd
          self.nixosModules.hardware-framework-13
          self.nixosModules.hardware-gpu-amd
          self.nixosModules.networking-bluetooth
          self.nixosModules.networking-wireless
          self.nixosModules.nix
          self.nixosModules.nix-build-aarch64
          self.nixosModules.nixpkgs
          self.nixosModules.programs-essentials
          self.nixosModules.programs-gnome-calendar
          self.nixosModules.programs-greetd
          self.nixosModules.programs-greetd-autologin
          self.nixosModules.programs-iotop
          self.nixosModules.programs-packages-common
          self.nixosModules.programs-secrets
          self.nixosModules.programs-sudo
          self.nixosModules.programs-terminfo
          self.nixosModules.prometheus-exporters-node
          self.nixosModules.prometheus-exporters-zfs
          self.nixosModules.services-deploy-rs
          self.nixosModules.services-fail2ban
          self.nixosModules.services-openssh
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
            hostId = "7375168d";
            system = {
              disk = "/dev/disk/by-id/nvme-WD_BLACK_SN850X_4000GB_251103801906";
              luksPasswordFile = "/tmp/root-disk-encryption.key";
              swapSize = "72G"; # Size of RAM + square root of RAM for hibernate
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

        services.logind.settings.Login = {
          HandleLidSwitch = "hybrid-sleep";
          HandleLidSwitchExternalPower = "suspend";
          HandlePowerKey = "suspend";
          HandlePowerKeyLongPress = "poweroff";
        };

        networking.interfaces.wlp192s0.useDHCP = true;
      };

    users.delay = {
      imports = with self.homeModules; [
        profile-hardware-laptop
        profile-hardware-wireless
        profile-hardware-workstation
        profile-ssh-keys-ring-0-tier
      ];

      node.wayland.idle.screenlock.fingerprint.enable = true;
    };
  };
}
