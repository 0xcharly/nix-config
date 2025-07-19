{
  inputs,
  pkgs,
  lib,
  ...
}: {
  packages = with pkgs; [
    cachix
    jq
    just
    home-manager

    alejandra
  ];

  languages.nix.enable = true;
  languages.nix.lsp.package = pkgs.nixd;

  scripts.fmt.exec = let
    fmt-opts = {
      projectRootFile = "flake.lock";
      programs = {
        alejandra.enable = true;
        prettier.enable = true;
        shfmt.enable = false;
      };
    };
    fmt = inputs.treefmt-nix.lib.mkWrapper pkgs fmt-opts;
  in
    lib.getExe fmt;
}
