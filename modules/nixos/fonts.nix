{config, ...}: {
  fonts = {
    # fontDir.enable is not supported on nix-darwin (fonts are enabled by default).
    fontDir.enable = !config.modules.usrenv.isHeadless;
  };
}
