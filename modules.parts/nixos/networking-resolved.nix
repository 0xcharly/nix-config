{
  flake.nixosModules.networking-resolved = {
    networking.networkmanager.dns = "systemd-resolved";
    services.resolved.enable = true;
  };
}
