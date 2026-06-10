{ inputs, moduleWithSystem, ... }:
{
  flake.homeModules.programs-nvim = moduleWithSystem (
    perSystem@{ config, ... }:
    homeManager@{ lib, pkgs, ... }:
    {
      options.my.programs.nvim = with lib; {
        package = mkOption {
          type = types.package;
          default = perSystem.config.packages.nvim;
          description = "The nvim package to install";
        };
      };

      config.home.packages = [
        homeManager.config.my.programs.nvim.package
        pkgs.neovide
      ];
    }
  );

  perSystem =
    { pkgs, ... }:
    {
      # The entire neoviw configuration without any dependency
      packages.nvim =
        let
          inherit (pkgs.stdenv.hostPlatform) system;
          mkNvimDist = pkgs.callPackage ./nvim/_mk-nvim-dist.nix { };
        in
        mkNvimDist {
          src = ./nvim/nvim-config;
          runtime = [ ./nvim/nvim-runtime ];
          patches = [ ];
          plugins = pkgs.callPackage ./nvim/_nvim-plugins.nix {
            inherit (inputs.nix-config-colorscheme.packages.${system}) colorscheme-nvim;
          };
        };
    };
}
