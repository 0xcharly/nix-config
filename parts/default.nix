{
  inputs,
  pkgs,
  ...
}: let
  lib = inputs.nixpkgs.lib.extend (self: _super:
    import ./lib {
      inherit inputs pkgs;
      lib = self;
      inherit (inputs.home-manager.lib) hm;
    });
in {
  # Explicitly import "parts" of a flake to compose it modularly.
  imports = [
    inputs.home-manager.flakeModules.home-manager
    ./args.nix # Args for the flake, consumed or propagated to parts by flake-parts.
    ./pkgs # Per-system packages exposed by the flake.
    ./usrlib # User-library providing utilities.
  ];

  # perSystem._module.args = {inherit lib;};
  flake = {inherit lib;};
}
