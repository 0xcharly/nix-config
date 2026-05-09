{ inputs, ... }:
{
  flake.homeModules.programs-cachix =
    { config, ... }:
    {
      imports = [ inputs.nix-config-secrets.homeModules.services-cachix ];

      age.secrets."services/cachix.dhall".path = "${config.xdg.configHome}/cachix/cachix.dhall";
    };
}
