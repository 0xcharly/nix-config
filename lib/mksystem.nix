# This function creates a NixOS system based on our VM setup for a
# particular architecture.
{
  homebrew,
  overlays,
  nixpkgs,
  inputs,
}: {
  configuration,
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
in
  osSystem {
    specialArgs = {inherit isCorpManaged isHeadless;};

    modules =
      [
        # Apply our overlays.
        {nixpkgs.overlays = overlays;}
        # Apply system configuration.
        configuration

        # Apply user configuration.
        hmModules.home-manager
        {
          home-manager.extraSpecialArgs = {inherit inputs isCorpManaged isHeadless;};
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "nix-backup";
          home-manager.users.${user} = import ../users/${user}/home-manager.nix;
        }
      ]
      ++ nixpkgs.lib.optionals isDarwin [
        # Nix-managed homebrew.
        homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true; # Install Homebrew under the default prefix.
            inherit user; # User owning the Homebrew prefix.
            autoMigrate = migrateHomebrew; # Enable when migrating from an existing setup.
          };
        }
      ];
  }
