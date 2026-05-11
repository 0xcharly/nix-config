{ inputs, moduleWithSystem, ... }:
{
  flake.homeModules.programs-nvim = moduleWithSystem (
    perSystem@{ config, ... }:
    homeManager@{ lib, ... }:
    {
      options.my.programs.nvim = with lib; {
        package = mkOption {
          type = types.package;
          default = perSystem.config.packages.nvim;
          description = "The nvim package to install";
        };
      };

      config = {
        home.packages = [ homeManager.config.my.programs.nvim.package ];
      };
    }
  );

  perSystem =
    { pkgs, ... }:
    {
      packages.nvim = inputs.nix-config-nvim.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };
}
