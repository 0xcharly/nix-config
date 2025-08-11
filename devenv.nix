{
  inputs,
  pkgs,
  lib,
  ...
}: {
  packages = with pkgs; [
    cachix
    deploy-rs
    jq
    just
    home-manager

    alejandra
  ];

  languages.nix = {
    enable = true;
    lsp.package = pkgs.nixd;
  };

  scripts = {
    rebuild.exec = let
      rebuildOptions = "--option accept-flake-config true --show-trace";
      switch =
        if pkgs.stdenv.isDarwin
        then ''
          sudo darwin-rebuild ${rebuildOptions} switch --flake .
        ''
        else ''
          if test $(grep ^NAME= /etc/os-release | cut -d= -f2) = "NixOS"; then
            sudo nixos-rebuild ${rebuildOptions} switch --flake .
          else
            home-manager ${rebuildOptions} switch -b hm.bak --flake .
          fi
        '';
    in
      switch;

    fmt.exec = let
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
  };
}
