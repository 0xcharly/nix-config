{
  inputs,
  moduleWithSystem,
  ...
}:
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
    { config, pkgs, ... }:
    {
      # The entire neoviw configuration without any dependency
      packages.nvim =
        let
          splicedpixel-nvim = pkgs.callPackage ./vimPlugins/_splicedpixel-nvim {
            inherit (config.packages) splicedpixel;
          };
          mkNvimDist = pkgs.callPackage ./nvim/_mk-nvim-dist.nix { };
        in
        mkNvimDist {
          src = ./nvim/nvim-config;
          runtime = [ ./nvim/nvim-runtime ];
          patches = [ ];
          plugins = pkgs.callPackage ./nvim/_nvim-plugins.nix {
            inherit splicedpixel-nvim;
          };
        };
    };
}
