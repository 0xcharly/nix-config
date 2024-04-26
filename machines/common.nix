{ pkgs, ... }:

{
  # Flakes support.
  nix = {
    # Enable flakes.
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';

    # Public binary cache used for derivations.
    settings = {
      substituters = ["https://0xcharly-nixos-config.cachix.org"];
      trusted-public-keys = ["0xcharly-nixos-config.cachix.org-1:qnguqEXJ4bEmJ8ceXbgB2R0rQbFqfWgxI+F7j4Bi6oU="];
    };
  };
}
