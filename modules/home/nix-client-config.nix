{config, ...}: {
  nixpkgs.config = {
    keep-derivations = true;
    keep-outputs = true;

    # Public binary caches used for derivations.
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://0xcharly-nixos-config.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "0xcharly-nixos-config.cachix.org-1:qnguqEXJ4bEmJ8ceXbgB2R0rQbFqfWgxI+F7j4Bi6oU="
    ];
  };

  # Use a ! prefix to skip validation at build time (which fails since the file
  # is not stored in the Nix store).
  nix.extraOptions = ''
    !include ${config.xdg.configHome}/nix/access-tokens.conf
  '';
}
