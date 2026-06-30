{ inputs, moduleWithSystem, ... }:
{
  flake.homeModules.programs-antigravity = moduleWithSystem (
    perSystem@{ config, ... }:
    {
      home.packages = with perSystem.config.packages; [ google-antigravity ];
    }
  );

  perSystem =
    { pkgs, ... }:
    {
      packages = with inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}; {
        inherit google-antigravity google-antigravity-cli google-antigravity-ide;
      };
    };
}
