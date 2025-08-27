{inputs, ...}: {
  config,
  lib,
  ...
}: {
  imports = [inputs.nix-config-secrets.modules.home.services-cachix];

  xdg.configFile."cachix/cachix.dhall".source =
    lib.file.mkOutOfStoreSymlink config.age.secrets."services/cachix.dhall".path;
}
