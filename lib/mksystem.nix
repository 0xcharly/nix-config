# This function creates a NixOS or nix-darwin system configuration.
{
  overlays,
  nixpkgs,
  inputs,
}: hostModule: {
  isCorpManaged ? false,
  isDarwin ? false,
  isHeadless ? false,
  migrateHomebrew ? false,
  user ? "delay",
}: let
  # NixOS vs nix-darwin functions.
  osSystem =
    if isDarwin
    then inputs.darwin.lib.darwinSystem
    else nixpkgs.lib.nixosSystem;
  hmModules =
    if isDarwin
    then inputs.home-manager.darwinModules
    else inputs.home-manager.nixosModules;
  nixIndexDb =
    if isDarwin
    then inputs.nix-index-database.darwinModules
    else inputs.nix-index-database.nixosModules;
in
  osSystem {
    specialArgs = {inherit isCorpManaged isHeadless;};

    modules =
      [
        # System options.
        {nixpkgs.overlays = overlays;}

        # System configuration.
        hostModule

        # User configuration.
        hmModules.home-manager
        {
          home-manager.extraSpecialArgs = {inherit inputs isCorpManaged isHeadless;};
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "nix-backup";
          home-manager.users.${user} = import ../users/${user}/home-manager.nix;
        }

        # nix-index-database configuration.
        nixIndexDb.nix-index
        {programs.nix-index-database.comma.enable = true;}
      ]
      ++ nixpkgs.lib.optionals isDarwin [
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
