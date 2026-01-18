{ flake, ... }:
{
  imports = [
    flake.modules.common.overlays

    flake.modules.iso.provisioning
  ];

  networking.hostName = "nixos";
  nixpkgs.hostPlatform = "x86_64-linux";
}
