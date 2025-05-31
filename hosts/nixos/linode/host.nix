# (Derived from https://www.linode.com/docs/guides/install-nixos-on-linode/)
#
# 1. Create three (3) disk images:
#    - Installer: 2048mb (raw)
#    - NixOS: rest (raw)
#
# 2. Boot in rescue mode with:
#    - /dev/sda -> Installer
#    - /dev/sdb -> NixOS
#
# 3. Once booted into Finnix (step 2):
#      update-ca-certificates
#      curl -L <ISO_URL> | tee >(dd of=/dev/sda) | sha256sum
#
# 4. Create two configuration profiles:
#    - Installer
#      - Kernel: Direct Disk
#      - /dev/sda -> NixOS
#      - /dev/sdb -> Installer
#      - Root device: /dev/sdb
#      - Helpers: distro and auto network helpers = off
#      - Leave others on their defaults
#    - Boot
#      - Kernel: Direct Disk
#      - /dev/sda -> NixOS
#      - Root device: /dev/sda
#      - Helpers: distro and auto network helpers = off
#      - Leave others on their defaults
#
# 5. Boot into installer profile and setup session:
#      passwd  # set nixos passwd
#
# 6. Get public IP address (ipconfig from the machine or from Linode UI).
#
# 7. Remote install (from a x86_64-linux machine):
#      just deploy-linode <ADDR>
#
# 8. Reboot into "Boot" profile.
{
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./fs.nix
  ];

  # See comment in modules/nixos/module.nix.
  system.stateVersion = "25.05";

  # No graphical environment.
  modules.usrenv.compositor = "headless";

  # Access tier.
  modules.system.security.accessTier = "basic";

  # Roles.
  modules.system.roles.nixos = {
    tailscaleNode = true;
    tailscalePublicNode = true;
  };

  networking = {
    hostName = "linode";

    enableIPv6 = true;
    tempAddresses = "disabled";

    # Most of Linode’s default images have had systemd’s predictable interface
    # names disabled. Because of this, most of Linode’s networking guides assume
    # an interface of eth0. Since your Linode runs in a virtual environment and
    # will have a single interface, it won’t encounter the issues that
    # predictable interface names were designed to solve.
    usePredictableInterfaceNames = false;

    # Interface is this on Linode VMs.
    interfaces.eth0 = {
      tempAddress = "disabled";
      useDHCP = true;
    };

    # Firewall on public machines.
    firewall.enable = true;
  };

  boot = {
    initrd = {
      availableKernelModules = ["virtio_pci" "virtio_scsi" "ahci" "sd_mod"];
      supportedFilesystems = ["btrfs"];
    };

    kernelPackages = pkgs.linuxPackages_latest; # Be careful updating this.
    kernelParams = ["console=ttyS0,19200n8"]; # Enable LISH.

    loader = {
      timeout = 10;
      grub = {
        enable = true;
        device = "nodev";
        forceInstall = true;

        # LISH config.
        extraConfig = ''
          serial --speed=19200 --unit=0 --word=8 --parity=no --stop=1;
          terminal_input serial;
          terminal_output serial
        '';
      };
    };
  };

  environment.systemPackages = with pkgs; [
    inetutils
    mtr
    sysstat
    linode-cli
  ];
}
