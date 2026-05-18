{ flake, ... }:
{
  imports = with flake.homeModules; [
    profile-hardware-wireless
    profile-hardware-workstation
    profile-ssh-keys-ring-0-tier
  ];

  home.stateVersion = "25.05";

  node = {
    wayland = {
      # https://wiki.hypr.land/0.41.2/Configuring/Monitors/#rotating
      #
      # | Transform              | x |
      # + ---------------------- + - +
      # | normal (no transforms) | 0 |
      # | 90 degrees             | 1 |
      # | 180 degrees            | 2 |
      # | 270 degrees            | 3 |
      # | flipped                | 4 |
      # | flipped + 90 degrees   | 5 |
      # | flipped + 180 degrees  | 6 |
      # | flipped + 270 degrees  | 7 |
      #
      hyprland.monitor = "DP-1, 3840x2160@59.997Hz, 0x0, 1.25, transform, 1";

      display.logicalResolution = {
        width = 3072;
        height = 1728;
      };

      idle = {
        screenlock.enable = true;
        suspend.enable = false;
      };
    };
  };
}
