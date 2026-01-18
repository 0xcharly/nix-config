{
  nix = {
    settings = rec {
      allowed-users = [ "delay" ];
      trusted-users = allowed-users;

      # Enable flakes.
      experimental-features = "nix-command flakes pipe-operators";
      accept-flake-config = true;

      # Add community cache
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://0xcharly-nixos-config.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "0xcharly-nixos-config.cachix.org-1:qnguqEXJ4bEmJ8ceXbgB2R0rQbFqfWgxI+F7j4Bi6oU="
      ];
    };

    gc.automatic = true; # Run garbage collection periodically. Default is weekly.
    optimise.automatic = true;
  };
}
