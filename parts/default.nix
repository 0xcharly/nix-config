{
  # Explicitly import "parts" of a flake to compose it modularly.
  imports = [
    ./usrlib # User-library providing utilities.
    ./pkgs # Per-system packages exposed by the flake.
    ./pre-commit.nix # Pre-commit hooks, to be ran before changes are committed.
    ./args.nix # Args for the flake, consumed or propagated to parts by flake-parts.
    ./fmt.nix # Formatter configurations via Treefmt.
    # ./iso-images.nix # Build recipes for local installation media.
    ./devshell.nix # devShells exposed by the flake.
  ];
}
