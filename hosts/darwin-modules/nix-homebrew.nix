{
  config,
  inputs,
  host,
  ...
}: {
  # Nix-managed homebrew.
  imports = [inputs.homebrew.darwinModules.nix-homebrew];

  nix-homebrew = {
    enable = true; # Install Homebrew under the default prefix.
    inherit (host) user; # User owning the Homebrew prefix.
    autoMigrate = config.settings.migrateHomebrew or false; # Enable when migrating from an existing setup.
  };
}