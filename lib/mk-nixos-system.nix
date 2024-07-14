# This function creates a NixOS system configuration.
{
  overlays,
  nixpkgs,
  inputs,
}: hostModule: {
  isCorpManaged ? false,
  isHeadless ? false,
  user ? "delay",
}:
nixpkgs.lib.nixosSystem {
  specialArgs = {inherit isCorpManaged isHeadless;};

  modules = [
    # System options.
    {nixpkgs.overlays = overlays;}

    # System configuration.
    hostModule

    # User configuration.
    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.extraSpecialArgs = {inherit inputs isCorpManaged isHeadless;};
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "nix-backup";
      home-manager.users.${user} = import ../users/${user};
    }

    # nix-index-database configuration.
    inputs.nix-index-database.nixosModules.nix-index
    {programs.nix-index-database.comma.enable = true;}
  ];
}
