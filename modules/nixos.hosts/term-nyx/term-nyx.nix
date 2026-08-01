{ self, inputs, ... }:
{
  my.hosts.term-nyx = {
    stateVersion = "25.05";

    nixosModule = {
      imports = [
        inputs.nix-config-secrets.nixosModules.default
        inputs.nix-config-secrets.nixosModules.jptax-fa5003-inputs
        inputs.nix-config-secrets.nixosModules.luks-remote-unlock
        inputs.nix-config-secrets.nixosModules.mail-account-delay
        inputs.nix-config-secrets.nixosModules.services-hoopsnake-term-nyx
        inputs.nix-config-secrets.nixosModules.services-tailscale
        inputs.nix-config-secrets.nixosModules.ssh-keys-ring-0-tier

        self.nixosModules.profile-fs-btrfs-workstation-baremetal
        self.nixosModules.profile-hardware-workstation
        self.nixosModules.profile-ssh-identities-ring0

        self.nixosModules.access-directory
        self.nixosModules.bootloader-systemd-boot
        self.nixosModules.hardware-cpu-amd
        self.nixosModules.hardware-gpu-amd
        self.nixosModules.hardware-wake-on-lan
        self.nixosModules.initrd-hoopsnake
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
        self.nixosModules.prometheus-exporters-smartctl
        self.nixosModules.services-adb
        self.nixosModules.services-fail2ban
        self.nixosModules.services-openssh
        self.nixosModules.services-pipewire
        self.nixosModules.services-removable-devices
        self.nixosModules.services-tailscale
        self.nixosModules.services-zmk-studio
        self.nixosModules.system-common
        self.nixosModules.system-fonts
      ];

      # System config
      node = {
        boot.initrd.hoopsnake.kernelModules = [ "igc" ];

        fs.btrfs.root = {
          disk = "/dev/disk/by-id/nvme-CT4000T700SSD3_2340E87BB2E0";
          luksPasswordFile = "/tmp/root-disk-encryption.key";
          swapSize = "4G";
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
        profile-ssh-identities-ring0
        profile-ssh-keys-ring-0-tier
      ];

      node.wayland.idle.suspend.deferOnSsh = true;
    };
  };
}
