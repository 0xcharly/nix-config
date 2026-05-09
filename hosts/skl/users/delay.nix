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
      hyprland.monitor = "DP-1, 3840x2160@59.997Hz, 0x0, 1.25";

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
