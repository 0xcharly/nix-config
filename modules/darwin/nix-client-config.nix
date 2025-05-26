{config, ...}: {
  nix.settings = {
    allowed-users = ["@admin"];
    trusted-users = ["@wheel" "root"];

    # Use a ! prefix to skip validation at build time (which fails since the file
    # is not stored in the Nix store).
    extraOptions = ''
      !include ${config.xdg.configHome}/nix/access-tokens.conf
    '';
  };
}
