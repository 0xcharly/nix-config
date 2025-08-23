# (Derived from https://www.linode.com/docs/guides/install-nixos-on-linode/)
#
# 1. Create two disk images:
#    - Installer: 2048mb (raw)
#    - SYSTEM: rest (raw)
#
# 2. Boot in rescue mode with:
#    - /dev/sda -> Installer
#    - /dev/sdb -> SYSTEM
#
# 3. Once booted into Finnix (step 2):
#      update-ca-certificates
#      curl -L <ISO_URL> | tee >(dd of=/dev/sda) | sha256sum
#
# 4. Create two configuration profiles:
#    - Installer
#      - Kernel: Direct Disk
#      - /dev/sda -> SYSTEM
#      - /dev/sdb -> Installer
#      - Root device: /dev/sdb
#      - Helpers: distro and auto network helpers = off
#      - Leave others on their defaults
#    - Boot
#      - Kernel: Direct Disk
#      - /dev/sda -> SYSTEM
#      - Root device: /dev/sda
#      - Helpers: distro and auto network helpers = off
#      - Leave others on their defaults
#
# 5. Boot into installer profile and setup session:
#      passwd  # set nixos passwd
#
# 6. Get public IPv4 address (ipconfig from the machine or from Linode UI).
#
# 7. Remote install (from a x86_64-linux machine):
#      just deploy-linode <ADDR>
#
# 8. Reboot into "Boot" profile.
#
# Optional: reclaim the installer partition
#
# 1. Shutdown the machine
#
# 2. With the Linode Manager console:
#   a. Delete the "Installer" configuration
#   a. Delete the "Installer" disk
#   b. Resize the "SYSTEM" partition
#
# 3. Boot in rescue mode with:
#    - /dev/sda -> SYSTEM
#
# 4. Use `parted` to resize the root partition.
#   a. It's possible that parted offers to fix the GPT automatically:
#
#     ```
#     (parted) print
#     Warning: Not all of the space available to /dev/sda appears to be used, you can
#     fix the GPT to use all of the space (an extra 4194304 blocks) or continue with
#     the current setting?
#     Fix/Ignore? Fix
#     Model: QEMU QEMU HARDDISK (scsi)
#     Disk /dev/sda: 26.8GB
#     Sector size (logical/physical): 512B/512B
#     Partition Table: gpt
#     Disk Flags:
#
#     Number  Start   End     Size    File system  Name              Flags
#      1      1049kB  2097kB  1049kB               disk-SYSTEM-boot  bios_grub
#      2      2097kB  24.7GB  24.7GB  btrfs        nixos
#     ```
#
#   b. Resize the root partition:
#       (parted) resizepart 2 100%
#
# 5. Reboot into the system:
#   a. Verify that BTRFS sees the slack:
#       sudo btrfs filesystem usage /
#
#       ```
#       Device size:                  21.98GiB
#       Device slack:                  2.00GiB
#       ```
#
#   b. Reclaim the slack:
#       sudo btrfs filesystem resize max /
#
#       ```
#       Device size:                  23.98GiB
#       Device slack:                    0.00B
#       ```
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
  modules = {
    usrenv.compositor = "headless";

    system = {
      security.accessTier = "basic";
      networking = {
        tailscaleNode = true;
        tailscalePublicNode = true;
      };
    };
  };

  node.services.prometheus.exporters.node.enable = true;

  networking = {
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
