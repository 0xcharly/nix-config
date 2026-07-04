{ self, ... }:
{
  flake.homeModules.environment-desktop-wayland = {
    imports = with self.homeModules; [
      programs-wayland
      programs-wayland-hyprland
      programs-wayland-quickshell
      programs-wayland-uwsm
    ];
  };
}
