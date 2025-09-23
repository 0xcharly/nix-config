{inputs, ...}: {config, ...}: {
  imports = [inputs.nix-config-secrets.modules.home.services-cachix];

  config.age.secrets."services/cachix.dhall".path = "${config.xdg.configHome}/cachix/cachix.dhall";
}
