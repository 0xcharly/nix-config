{config, ...}: {
  # Use a ! prefix to skip validation at build time (which fails since the file
  # is not store in the Nix store).
  nix.extraOptions = ''
    !include ${config.xdg.configHome}/nix/access-tokens.conf
  '';
}
