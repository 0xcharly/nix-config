{ self, ... }:
{
  flake.nixosModules.profile-hardware-workstation = {
    imports = with self.nixosModules; [
      colors-console
      environment-man-pages
      programs-power-management
    ];

    node.networking.tailscale.operator.enable = true;
  };
}
