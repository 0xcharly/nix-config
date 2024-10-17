{
  description = "Zellij Sessionizer plugin devshell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = {
    nixpkgs,
    rust-overlay,
    flake-utils,
    treefmt-nix,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        overlays = [(import rust-overlay)];
        pkgs = import nixpkgs {inherit system overlays;};
        treefmt = treefmt-nix.lib.evalModule pkgs .config/treefmt.nix;
      in {
        devShells.default = with pkgs;
          mkShell {
            buildInputs = [
              # Support tools.
              just # Command runner

              # Nix tools.
              nixd # LSP
              alejandra # Formatter

              # Markdown tools.
              markdownlint-cli # LSP

              # Rust tools.
              bacon # Diagnostics
              rust-analyzer # LSP
              (pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml) # Toolchain
            ];

            formatter = treefmt.config.build.wrapper;

            # Set up pre-commit hooks when user enters the shell.
            shellHook = let
              inherit (pkgs) lib;
              recipes = {
                fmt = {
                  text = ''${lib.getExe treefmt.config.build.wrapper} --on-unmatched=info'';
                  doc = "Format all files in this directory and its subdirectories.";
                };
              };
              commonJustfile = pkgs.writeTextFile {
                name = "justfile.incl";
                text =
                  lib.concatStringsSep "\n"
                  (lib.mapAttrsToList (name: recipe: ''
                      [doc("${recipe.doc}")]
                      ${name}:
                          ${recipe.text}
                    '')
                    recipes);
              };
            in ''
              ln -sf ${builtins.toString commonJustfile} ./.justfile.incl
            '';
          };
      }
    );
}
