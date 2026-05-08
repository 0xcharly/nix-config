{ flake, ... }:
{
  imports = [ flake.nixosModules.iso-provisioning ];

  networking.hostName = "nixos";
  nixpkgs.hostPlatform = "x86_64-linux";
}
