{
  nix.settings = rec {
    allowed-users = ["delay"];
    trusted-users = allowed-users;

    # Enable flakes.
    experimental-features = "nix-command flakes";
    accept-flake-config = true;
    keep-derivations = true;
    keep-outputs = true;

    # Public binary caches used for derivations.
    substituters = [
      "https://cache.nixos.org"
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
      "https://0xcharly-nixos-config.cachix.org"
    ];
    trusted-substituters = substituters;
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "0xcharly-nixos-config.cachix.org-1:qnguqEXJ4bEmJ8ceXbgB2R0rQbFqfWgxI+F7j4Bi6oU="
    ];
  };

  nix.gc.automatic = true; # Run garbage collection periodically. Default is weekly.
}
