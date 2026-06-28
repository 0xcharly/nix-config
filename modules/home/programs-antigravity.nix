{ inputs, moduleWithSystem, ... }:
{
  flake.homeModules.programs-antigravity = moduleWithSystem (
    perSystem@{ config, ... }:
    {
      home.packages = [
        perSystem.config.packages.antigravity
        perSystem.config.packages.antigravity-cli
      ];
    }
  );

  perSystem =
    { pkgs, ... }:
    {
      packages = {
        antigravity = inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
        antigravity-cli =
          inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-cli;
        antigravity-ide =
          inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-ide;
      };
    };
}
