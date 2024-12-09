{config, ...}: {
  nix.settings.allowed-users = ["@wheel"];

  # Use a ! prefix to skip validation at build time (which fails since the file
  # is not store in the Nix store).
  nix.extraOptions = ''
    !include ${config.modules.system.users.delay.home}/.config/nix/nix.conf
  '';
}
