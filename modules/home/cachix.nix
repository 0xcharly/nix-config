{ inputs, ... }:
{ config, ... }:
{
  imports = [ inputs.nix-config-secrets.homeModules.services-cachix ];

  config.age.secrets."services/cachix.dhall".path = "${config.xdg.configHome}/cachix/cachix.dhall";
}
