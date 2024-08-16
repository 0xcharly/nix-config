{inputs, ...}: {
  perSystem = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (pkgs.stdenv) isDarwin;
    upkgs =
      import (
        if isDarwin
        then inputs.nixpkgs-darwin
        else inputs.nixpkgs
      ) {
        inherit (pkgs) overlays system;
        config.allowUnfreePredicate = pkg:
          pkgs.stdenv.isDarwin && (builtins.elem (pkgs.lib.getName pkg) ["1password-cli"]);
      };
  in {
    devShells.default = upkgs.mkShell {
      packages =
        [
          # Packages provided by flake-parts modules
          config.treefmt.build.wrapper # Quick formatting tree-wide with `treefmt`

          upkgs.alejandra
          upkgs.cachix
          upkgs.fish
          upkgs.jq
          upkgs.just
          upkgs.lua-language-server
          upkgs.markdownlint-cli
          upkgs.nixd
          upkgs.stylua
        ]
        ++ (lib.optionals isDarwin [upkgs._1password]);

      # Set up pre-commit hooks when user enters the shell.
      shellHook = ''
        ${config.pre-commit.installationScript}
      '';

      # Tell Direnv to shut up.
      DIRENV_LOG_FORMAT = "";
    };
  };
}
