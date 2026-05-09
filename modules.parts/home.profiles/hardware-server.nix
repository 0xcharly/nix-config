{ self, ... }:
{
  flake.homeModules.profile-hardware-server = {
    imports = with self.homeModules; [
      account-essentials
      home-manager-nixos
      nixpkgs
      programs-atuin-sync
      secrets
    ];
  };
}
