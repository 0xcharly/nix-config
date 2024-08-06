{inputs, ...}: {
  perSystem = {
    config,
    pkgs,
    ...
  }: let
    upkgs =
      import (
        if pkgs.stdenv.isDarwin
        then inputs.nixpkgs-darwin
        else inputs.nixpkgs
      ) {
        inherit (pkgs) overlays system;
        config.allowUnfreePredicate = pkg:
          pkgs.stdenv.isDarwin && (builtins.elem (pkgs.lib.getName pkg) ["1password-cli"]);
      };
  in {
    devShells.default = upkgs.mkShell {
      nativeBuildInputs = [
        upkgs._1password
        upkgs.alejandra
        upkgs.cachix
        upkgs.jq
        upkgs.just
        upkgs.markdownlint-cli
        upkgs.nixd
        config.treefmt.build.wrapper
      ];

      shellHook = ''
        ${config.pre-commit.installationScript}
      '';
    };

    pre-commit = {
      pkgs = upkgs;
      settings = {
        hooks = {
          alejandra.enable = true;
          markdownlint = {
            enable = true;
            settings.configuration.MD034 = false;
          };
        };
      };
    };
  };
}
