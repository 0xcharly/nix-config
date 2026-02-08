{
  services = {
    # Upower is a DBus service that provides power management support to applications
    upower.enable = true;

    # Enable power profiles via upower
    power-profiles-daemon.enable = true;
  };
}
