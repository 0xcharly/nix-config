{pkgs, ...}: {
  imports = [
    ./fs.nix
  ];

  # No graphical environment.
  modules.usrenv.compositor = "headless";

  # Most of Linode’s default images have had systemd’s predictable interface
  # names disabled. Because of this, most of Linode’s networking guides assume
  # an interface of eth0. Since your Linode runs in a virtual environment and
  # will have a single interface, it won’t encounter the issues that
  # predictable interface names were designed to solve.
  networking.usePredictableInterfaceNames = false;

  # Interface is this on Linode VMs.
  networking.interfaces.enp0s5.useDHCP = true;

  # Reenable firewall on public machines.
  networking.firewall.enable = true;

  boot.initrd.availableKernelModules = [
    "ata_piix"
    "mptspi"
    "uhci_hcd"
    "ehci_pci"
    "sd_mod"
    "sr_mod"
    "nvme"
  ];
  boot.initrd.kernelModules = [];
  boot.kernelModules = [];
  boot.extraModulePackages = [];

  # Be careful updating this.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Enable LISH.
  # https://www.linode.com/docs/guides/install-nixos-on-linode/#enable-lish
  boot.kernelParams = ["console=ttyS0,19200n8"];
  boot.loader.grub.extraConfig = ''
    serial --speed=19200 --unit=0 --word=8 --parity=no --stop=1;
    terminal_input serial;
    terminal_output serial
  '';

  # Configure GRUB.
  # https://www.linode.com/docs/guides/install-nixos-on-linode/#configure-grub
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.forceInstall = true;
  boot.loader.timeout = 10;
}
