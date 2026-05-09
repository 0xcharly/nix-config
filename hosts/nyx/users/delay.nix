{ flake, ... }:
{
  imports = with flake.homeModules; [
    opencode

    profile-hardware-workstation
    profile-ssh-keys-ring-0-tier
  ];

  home.stateVersion = "25.05";

  node = {
    wayland = {
      hyprland.monitor = "DP-3, 6016x3384@60.00Hz, 0x0, 2.00";

      display.logicalResolution = {
        width = 3008;
        height = 1692;
      };

      arcshell.wallpaper.animate = true;
    };
  };
}
