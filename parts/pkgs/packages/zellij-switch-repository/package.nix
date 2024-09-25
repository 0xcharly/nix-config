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
  cargoTOML = builtins.fromTOML (builtins.readFile (src + "/Cargo.toml"));
  inherit (cargoTOML.package) version name;

  cargoLock = {
    lockFile = builtins.path {
      path = src + "/Cargo.lock";
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
      cargo build --package ${name} --release --target=wasm32-wasip1
      mkdir -p $out/bin;
    '';

    installPhase =
      if optimize
      then ''
        wasm-opt \
          -Oz target/wasm32-wasip1/release/${name}.wasm \
          -o $out/bin/${name}.wasm \
          --enable-bulk-memory
        # substituteInPlace dev.kdl --replace 'file:target/wasm32-wasip1/debug/${name}.wasm' "${placeholder "out"}"
        # mkdir -p $out/share;
        # cp dev.kdl $out/share/${name}.kdl
      ''
      else ''
        mv target/wasm32-wasip1/release/${name}.wasm $out/bin/${name}.wasm
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
