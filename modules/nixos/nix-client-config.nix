{config, ...}: {
  nix.settings = {
    # Sudo's users.
    allowed-users = ["@wheel"];

    # Additional public binary caches used for derivations.
    substituters = [
      "https://hyprland.cachix.org"
    ];
    trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };

  # Use a ! prefix to skip validation at build time (which fails since the file
  # is not stored in the Nix store).
  nix.extraOptions = ''
    !include ${config.age.secrets."services/nix-access-tokens.conf".path}
  '';
}
