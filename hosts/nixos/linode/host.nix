# (Derived from https://www.linode.com/docs/guides/install-nixos-on-linode/)
#
# 1. Create three (3) disk images:
#    - Installer: 1024mb (ext4)
#    - Swap: 512mb (swap)
#    - NixOS: rest (ext4)
#
# 2. Boot in rescue mode with:
#    - /dev/sda -> Installer
#    # (optional)
#    - /dev/sdb -> Swap
#    - /dev/sdc -> NixOS
#
# 3. Once booted into Finnix (step 2):
#      update-ca-certificates
#      curl -L <ISO_URL> | tee >(dd of=/dev/sda) | sha256sum
#
# 4. Create two configuration profiles:
#    - Installer
#      - Kernel: Direct Disk
#      - /dev/sda -> NixOS
#      - /dev/sdb -> Swap
#      - /dev/sdc -> Installer
#      - Root device: /dev/sdc
#      - Helpers: distro and auto network helpers = off
#      - Leave others on their defaults
#    - Boot
#      - Kernel: Direct Disk
#      - /dev/sda -> NixOS
#      - /dev/sdb -> Swap
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
#
# 9. Resume (and complete) `deploy-linode` script.
{
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./fs.nix
    ./secrets.nix
  ];

  # No graphical environment.
  modules.usrenv.compositor = "headless";

  # Use Zellij for repository management.
  modules.usrenv.switcherApp = "zellij";

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

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      # PermitRootLogin = pkgs.lib.mkForce "yes"; # TODO: change me (can we pass this dynamically during setup instead?)
      PermitRootLogin = "no"; # TODO: change me (can we pass this dynamically during setup instead?)
      PasswordAuthentication = false;
    };
  };

  users.users.delay.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKZCryAJK8VIlg5MjGcvBwma20oMzirFDoB3nINV5Bks"
  ];

  boot = {
    initrd = {
      availableKernelModules = ["virtio_pci" "virtio_scsi" "ahci" "sd_mod"];
      kernelModules = [];
    };
    kernelModules = [];
    extraModulePackages = [];

    # Be careful updating this.
    kernelPackages = pkgs.linuxPackages_latest;

    # Enable LISH.
    # https://www.linode.com/docs/guides/install-nixos-on-linode/#enable-lish
    kernelParams = ["console=ttyS0,19200n8"];

    loader = {
      timeout = 10;
      grub = {
        enable = true;
        # Needed for LISH.
        extraConfig = ''
          serial --speed=19200 --unit=0 --word=8 --parity=no --stop=1;
          terminal_input serial;
          terminal_output serial
        '';

        # Configure GRUB.
        # https://www.linode.com/docs/guides/install-nixos-on-linode/#configure-grub
        device = "/dev/sda";

        # GRUB will complain about blocklists when trying to install grub on a
        # partition-less disk. This tells it to ignore the warning and carry on.
        forceInstall = true;
      };
      # Disable globals
      efi.canTouchEfiVariables = false;
      systemd-boot.enable = false;
    };
  };

  environment.systemPackages = with pkgs; [
    inetutils
    mtr
    sysstat
    linode-cli
  ];
}
