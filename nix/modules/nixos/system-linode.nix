{pkgs, ...}: {
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
    initrd.availableKernelModules = [
      "ahci"
      "nvme"
      "sd_mod"
      "sd_mod"
      "usbhid"
      "virtio_pci"
      "virtio_scsi"
      "xhci_pci"
    ];

    # LISH config.
    kernelParams = ["console=ttyS0,19200n8"];
    loader = {
      timeout = 10;
      grub.extraConfig = ''
        serial --speed=19200 --unit=0 --word=8 --parity=no --stop=1;
        terminal_input serial;
        terminal_output serial
      '';
    };
  };

  environment.systemPackages = with pkgs; [
    inetutils
    mtr
    sysstat
    linode-cli
  ];
}
