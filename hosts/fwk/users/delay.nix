{ flake, ... }:
{
  imports = with flake.homeModules; [
    opencode
    pkgs-laptop-tui

    profile-hardware-workstation
    profile-ssh-keys-ring-0-tier
  ];

  home.stateVersion = "25.05";

  node = {
    wayland = {
      hyprland.monitor = "eDP-1, 2880x1920@120.00000, 0x0, 1.50";

      display.logicalResolution = {
        width = 1920;
        height = 1280;
      };

      pip = {
        width = 640;
        height = 360;
      };

      idle = {
        suspend.timeout = 15 * 60; # 15 minutes.
        hibernate = {
          enable = true;
          timeout = 30 * 60; # 30 minutes.
        };
        screenlock.fingerprint.enable = true;
      };

      arcshell.modules.power = true;
    };
  };
}
