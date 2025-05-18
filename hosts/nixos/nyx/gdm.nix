{
  # Set gdm monitor configuration (2x scale for 4K @ 240Hz monitor).
  systemd.tmpfiles.rules = [
    ''L+ /run/gdm/.config/monitors.xml - - - - ${./gdm/monitors.xml}''
  ];
}
