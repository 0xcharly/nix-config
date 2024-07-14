# This function creates a nix-darwin system configuration.
{
  overlays,
  inputs,
}: hostModule: {
  isCorpManaged ? false,
  migrateHomebrew ? false,
  user ? "delay",
}:
inputs.darwin.lib.darwinSystem {
  specialArgs = {
    inherit isCorpManaged;
    isHeadless = false;
  };

  modules = [
    # System options.
    {nixpkgs.overlays = overlays;}

    # System configuration.
    hostModule

    # User configuration.
    inputs.home-manager.darwinModules.home-manager
    {
      home-manager.extraSpecialArgs = {
        inherit inputs isCorpManaged;
        isHeadless = false;
      };
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "nix-backup";
      home-manager.users.${user} = import ../users/${user};
    }

    # nix-index-database configuration.
    inputs.nix-index-database.darwinModules.nix-index
    {programs.nix-index-database.comma.enable = true;}

    # Nix-managed homebrew.
    inputs.homebrew.darwinModules.nix-homebrew
    {
      nix-homebrew = {
        enable = true; # Install Homebrew under the default prefix.
        inherit user; # User owning the Homebrew prefix.
        autoMigrate = migrateHomebrew; # Enable when migrating from an existing setup.
      };
    }
  ];
}
