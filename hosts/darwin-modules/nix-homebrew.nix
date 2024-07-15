{
  inputs,
  hostSettings,
  ...
}:
# Nix-managed homebrew.
inputs.homebrew.darwinModules.nix-homebrew
{
  nix-homebrew = {
    enable = true; # Install Homebrew under the default prefix.
    inherit (hostSettings) user; # User owning the Homebrew prefix.
    autoMigrate = hostSettings.migrateHomebrew; # Enable when migrating from an existing setup.
  };
}
