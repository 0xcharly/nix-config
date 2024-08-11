{config-manager, ...}: {
  imports = with config-manager; [
    system.vm-disks
    system.vm-linode
  ];

  # No graphical environment.
  settings.compositor = "headless";

  # Most of Linode’s default images have had systemd’s predictable interface
  # names disabled. Because of this, most of Linode’s networking guides assume
  # an interface of eth0. Since your Linode runs in a virtual environment and
  # will have a single interface, it won’t encounter the issues that
  # predictable interface names were designed to solve.
  networking.usePredictableInterfaceNames = false;

  # Interface is this on Linode VMs.
  networking.interfaces.eth0.useDHCP = true;

  # Reenable firewall on public machines.
  networking.firewall.enable = true;
}
