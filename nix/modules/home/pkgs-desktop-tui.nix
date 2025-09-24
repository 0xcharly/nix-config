{
  pkgs,
  # pkgs',
  ...
}: {
  home.packages = with pkgs; [
    blueberry # Bluetooth.
  ];
  # # TODO(25.11): install these from the stable channel.
  # ++ (with pkgs'; [
  #   wiremix # Not available on the stable channel yet.
  # ]);
}
