{
  nix.settings = rec {
    keep-derivations = true;
    keep-outputs = true;

    # Public binary caches used for derivations.
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://0xcharly-nixos-config.cachix.org"
    ];
    trusted-substituters = substituters;
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "0xcharly-nixos-config.cachix.org-1:qnguqEXJ4bEmJ8ceXbgB2R0rQbFqfWgxI+F7j4Bi6oU="
    ];
  };

  nix.optimise.automatic = true; # Optimise nix store regularly. Defaults to weekly.
}
