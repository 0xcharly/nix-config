{
  stdenv,
  lib,
  cmake,
  pkg-config,
  hidapi,
}:
let
  version = "1.0.0";
in
stdenv.mkDerivation {
  pname = "apdbctl";
  inherit version;

  src = ./.;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    hidapi
  ];

  cmakeFlags = [
    (lib.cmakeFeature "VERSION" version)
  ];

  cmakeBuildType = "RelWithDebInfo";

  meta = with lib; {
    description = "Apple Pro Display XDR Brightness control";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
