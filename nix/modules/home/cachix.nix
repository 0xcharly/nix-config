{inputs, ...}: {
  config,
  ...
}: {
  imports = [inputs.nix-config-secrets.modules.home.services-cachix];

  xdg.configFile."cachix/cachix.dhall".source =
    config.lib.file.mkOutOfStoreSymlink config.age.secrets."services/cachix.dhall".path;
}
