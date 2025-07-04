{inputs, ...}: {
  # Explicitly import "parts" of a flake to compose it modularly.
  imports = [
    inputs.home-manager.flakeModules.home-manager
    ./args.nix # Args for the flake, consumed or propagated to parts by flake-parts.
    ./pkgs # Per-system packages exposed by the flake.
    ./usrlib # User-library providing utilities.
  ];
}
