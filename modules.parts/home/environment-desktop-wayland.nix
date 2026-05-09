{ self, ... }:
{
  flake.homeModules.environment-desktop-wayland = {
    imports = with self.homeModules; [
      programs-wayland
      programs-wayland-hyprland
      programs-wayland-hyprland-smartgaps
      programs-wayland-notifications
      programs-wayland-quickshell
      programs-wayland-uwsm
    ];
  };
}
