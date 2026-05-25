{
  flake.homeModules.services-usb-auto-mount = {
    services.udiskie.enable = true; # USB automount (requires udisks2 service enabled)
  };
}
