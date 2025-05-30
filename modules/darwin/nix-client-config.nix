{
  nix.settings = {
    allowed-users = ["@admin"];
    trusted-users = ["@wheel"];
  };

  # Use a ! prefix to skip validation at build time (which fails since the file
  # is not stored in the Nix store).
  nix.extraOptions = ''
    !include /etc/nix/access-tokens.conf
  '';
}
