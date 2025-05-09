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
          upkgs.alejandra
          upkgs.cachix
          upkgs.jq
          upkgs.just
          upkgs.lua-language-server
          upkgs.markdownlint-cli
          upkgs.nixd
          upkgs.prettierd
          upkgs.stylua
        ]
        ++ (lib.optionals isDarwin [upkgs._1password-cli]);

      # Set up pre-commit hooks when user enters the shell.
      shellHook = let
        recipes = {
          fmt = {
            text = ''${lib.getExe config.treefmt.build.wrapper}'';
            doc = "Format all files in the repository";
          };
          brew-update = {
            text = ''/opt/homebrew/bin/brew update and /opt/homebrew/bin/brew upgrade'';
            doc = "Update Homebrew packages";
            tag = ["macos"];
          };
        };
        commonJustfile = pkgs.writeTextFile {
          name = "justfile.incl";
          text =
            lib.concatStringsSep "\n"
            (lib.mapAttrsToList (name: recipe: ''
                ${lib.concatStringsSep "\n" (builtins.map (tag: "[${tag}]") (recipe.tags or []))}
                [group('devshell')]
                [doc("${recipe.doc}")]
                ${name}:
                    ${recipe.text}
              '')
              recipes);
        };
      in ''
        ${config.pre-commit.installationScript}
        ln -sf ${builtins.toString commonJustfile} ./.justfile.incl
      '';

      # Tell Direnv to shut up.
      DIRENV_LOG_FORMAT = "";
    };
  };
}
