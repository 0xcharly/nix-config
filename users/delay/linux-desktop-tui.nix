{
  pkgs,
  pkgs',
  lib,
  ...
} @ args: let
  inherit ((lib.user.getUserConfig args).modules.usrenv) isLinuxDesktop;
in
  lib.mkIf isLinuxDesktop {
    home.packages = with pkgs;
      [
        blueberry # Bluetooth.
        impala # Wifi.
      ]
      # TODO(25.11): install these from the stable channel.
      ++ (with pkgs'; [
        wiremix # Not available on the stable channel yet.
      ]);
  }
