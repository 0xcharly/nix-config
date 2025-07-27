{
  # Set gdm monitor configuration.
  systemd.tmpfiles.rules = [
    ''L+ /run/gdm/.config/monitors.xml - - - - ${./gdm/monitors-pro-display-hdr.xml}''
  ];
}
