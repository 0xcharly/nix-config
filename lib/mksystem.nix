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

    modules = [
      # Apply our overlays.
      {nixpkgs.overlays = overlays;}

      configuration
      hmModules.home-manager
      {
        home-manager.extraSpecialArgs = {inherit inputs isCorpManaged isHeadless;};
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "nix-backup";
        home-manager.users.${user} = import ../users/${user}/home-manager.nix;
      }

      homebrew.darwinModules.nix-homebrew
      {
        nix-homebrew = {
          # Install Homebrew under the default prefix
          enable = true;

          # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
          enableRosetta = false;

          # User owning the Homebrew prefix
          inherit user;

          # Automatically migrate existing Homebrew installations
          # autoMigrate = true;
        };
      }
    ];
  }
