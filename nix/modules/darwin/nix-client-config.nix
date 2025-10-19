{config, ...}: {
  nix = {
    settings = {
      allowed-users = ["@admin"];
      trusted-users = ["@wheel"];
    };

    # Use a ! prefix to skip validation at build time (which fails since the file
    # is not stored in the Nix store).
    extraOptions = ''
      !include ${config.age.secrets."services/nix-access-tokens.conf".path}
    '';
  };
}
