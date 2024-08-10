{
  config-manager,
  pkgs,
  ...
}: {
  imports = with config-manager; [
    system.vm-aarch64
    system.vmware-guest
    system.nixos-compositor-common
    system.nixos-x11
    system.nixos-wayland
  ];

  # Wayland crashes on VMWare Fusion.
  settings.compositor = "x11";

  # Setup qemu so we can run x86_64 binaries
  boot.binfmt.emulatedSystems = ["x86_64-linux"];

  # Disable the default module and import our override that works on aarch64.
  # TODO: revert when https://github.com/NixOS/nixpkgs/pull/326395 is submitted.
  disabledModules = ["virtualisation/vmware-guest.nix"];

  # This is needed for the vmware user tools clipboard to work.
  environment.systemPackages = [pkgs.gtkmm3];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # VMware, Parallels both only support this being 0 otherwise you see
  # "error switching console mode" on boot.
  boot.loader.systemd-boot.consoleMode = "0";

  # Don't require password for sudo.
  security.sudo.wheelNeedsPassword = false;

  # Interface names on M1, M3.
  networking.interfaces.ens160.useDHCP = true; # NAT adapter.

  # Disable the firewall since we're in a VM and we want to make it
  # easy to visit stuff in here. We only use NAT networking anyways.
  networking.firewall.enable = false;

  # Lots of stuff that uses aarch64 that claims doesn't work, but actually works.
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;

  # This works through our custom module imported above
  virtualisation.vmware.guest.enable = true;

  # Share our host filesystem
  fileSystems."/host" = {
    fsType = "fuse./run/current-system/sw/bin/vmhgfs-fuse";
    device = ".host:/";
    options = [
      "umask=22"
      "uid=1000"
      "gid=1000"
      "allow_other"
      "auto_unmount"
      "defaults"
    ];
  };
}
