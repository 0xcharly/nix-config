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
        config.treefmt.build.wrapper
        upkgs._1password
        upkgs.alejandra
        upkgs.cachix
        upkgs.jq
        upkgs.just
        upkgs.lua-language-server
        upkgs.markdownlint-cli
        upkgs.nixd
        upkgs.stylua
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
          # TODO: enable when the static analyzer can resolve the `vim` module.
          # luacheck.enable = true;
          markdownlint = {
            enable = true;
            settings.configuration.MD034 = false;
          };
        };
      };
    };
  };
}
