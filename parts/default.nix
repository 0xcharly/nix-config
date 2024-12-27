{
  # Explicitly import "parts" of a flake to compose it modularly.
  imports = [
    ./apps # "Runnables" exposed by the flake, used with `nix run .#<appName`.
    ./args.nix # Args for the flake, consumed or propagated to parts by flake-parts.
    ./cmd-fmt.nix # Formatter configurations via Treefmt.
    ./devshells.nix # devShells exposed by the flake.
    ./git-hooks.nix # Pre-commit hooks, to be ran before changes are committed.
    ./pkgs # Per-system packages exposed by the flake.
    ./usrlib # User-library providing utilities.
    # ./iso-images.nix # Build recipes for local installation media.
  ];
}
