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

    bacon
    watchexec

    nixd
    alejandra

    # TODO: delete and repackage correctly.
    rustup

    # TODO: pipe rust-toolchain down to this file.
    # (callPackage ./package.nix {})

    # Used to run `select.fish`.
    ansifilter
    coreutils
    (callPackage ../path-strip-prefix/package.nix {})
  ];
}
