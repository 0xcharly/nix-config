{ inputs, moduleWithSystem, ... }:
{
  flake.homeModules.programs-hunk = moduleWithSystem (
    perSystem@{ config, ... }:
    {
      home.packages = with perSystem.config.packages; [ hunk ];
    }
  );

  perSystem =
    { pkgs, ... }:
    {
      packages = with inputs.hunk.packages.${pkgs.stdenv.hostPlatform.system}; {
        inherit hunk;
      };
    };
}
