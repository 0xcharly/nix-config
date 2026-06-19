{
  flake.nixosModules.profile-hardware-linode =
    { modulesPath, ... }:
    {
      imports = [
        "${modulesPath}/profiles/qemu-guest.nix"
      ];
    };
}
