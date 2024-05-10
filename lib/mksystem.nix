# This function creates a NixOS system based on our VM setup for a
# particular architecture.
{
  nixpkgs,
  inputs,
}: {
  hostConfiguration,
  osConfiguration,
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
    # Replaced with |opt.hostPlatform|. TODO: need to update NixOS config.
    # system = hostPlatform;
    specialArgs = {inherit isCorpManaged isHeadless;};

    modules = [
      hostConfiguration
      osConfiguration
      hmModules.home-manager
      {
        home-manager.extraSpecialArgs = {inherit isCorpManaged isHeadless;};
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.${user} = import ../users/${user}/home-manager.nix {
          inputs = inputs;
        };
      }
    ];
  }
