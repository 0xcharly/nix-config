{ self, ... }:
{
  flake.homeModules.profile-hardware-server = {
    imports = with self.homeModules; [
      account-essentials
      atuin-sync
      home-manager-nixos
      nixpkgs
      secrets
    ];
  };
}
