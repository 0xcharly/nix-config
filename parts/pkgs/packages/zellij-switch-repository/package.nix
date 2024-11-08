{
  lib,
  stdenv,
  makeRustPlatform,
  rust-bin,
  darwin,
  binaryen,
  optimize ? true,
}: let
  src = ./.;
  cargoTOML = builtins.fromTOML (builtins.readFile (src + /Cargo.toml));
  inherit (cargoTOML.package) version name;

  cargoLock = {
    lockFile = builtins.path {
      path = src + /Cargo.lock;
      name = "Cargo.lock";
    };
    allowBuiltinFetchGit = true;
  };

  rustToolchainTOML = rust-bin.fromRustupToolchainFile (src + /rust-toolchain.toml);
  rustc = rustToolchainTOML;
  cargo = rustToolchainTOML;

  rustPlatform = makeRustPlatform {inherit cargo rustc;};
in
  rustPlatform.buildRustPackage {
    pname = "zellij-switch-session";

    inherit
      cargoLock
      name
      version
      src
      stdenv
      ;

    buildInputs = lib.optionals stdenv.isDarwin (
      with darwin.apple_sdk.frameworks; [
        DiskArbitration
        Foundation
      ]
    );

    nativeBuildInputs = [
      binaryen
    ];

    buildPhase = ''
      runHook preBuild
      cargo build --manifest-path ./Cargo.toml --release --target=wasm32-wasip1
      cargo build --manifest-path ./find-git-repositories/Cargo.toml --release
      runHook postBuild
    '';

    installPhase =
      ''
        runHook preInstall
        cargo install --frozen --path . --root "$out" --target=wasm32-wasip1
        cargo install --frozen --path ./find-git-repositories --root "$out"
      ''
      + lib.optionalString optimize ''
        wasm-opt \
          -Oz "$out/bin/${name}.wasm" \
          -o "$out/bin/${name}.wasm" \
          --enable-bulk-memory
      ''
      + ''
        runHook postInstall
      '';
    doCheck = false;

    meta = {
      description = "Session switcher plugin for Zellij";
      license = lib.licenses.mit;
      maintainers = []; # TODO: setup lib.maintainers._0xcharly
      platforms = lib.platforms.unix;
      mainProgram = "${name}.wasm";
    };
  }
