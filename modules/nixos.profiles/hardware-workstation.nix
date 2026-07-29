{ self, ... }:
{
  flake.nixosModules.profile-hardware-workstation = {
    imports = with self.nixosModules; [
      colors-console
      environment-man-pages
      programs-password-managers
      programs-power-management
    ];

    node.networking.tailscale.operator.enable = true;
  };
}
