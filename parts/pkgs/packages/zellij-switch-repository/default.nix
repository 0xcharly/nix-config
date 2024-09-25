{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  packages = with pkgs; [
    # cargo
    # cargo-wasi
    curl
    # darwin.apple_sdk.frameworks.CoreServices
    libiconv
    # rust-analyzer
    # rustfmt
    watchexec

    nixd
    alejandra

    # TODO: delete and repackage correctly.
    rustup

    (callPackage ./package.nix {})
  ];
}
