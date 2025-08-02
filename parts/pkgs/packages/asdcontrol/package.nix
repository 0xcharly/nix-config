{
  lib,
  stdenv,
  fetchFromGitHub,
  ...
}:
stdenv.mkDerivation {
  pname = "asdcontrol";
  version = "git-2025-04-28";

  src = fetchFromGitHub {
    owner = "nikosdion";
    repo = "asdcontrol";
    rev = "490469c95c73651d8447b5a5ce0afb1ffe54cfca";
    sha256 = "sha256-fEtBzntB1ieP4+MapzGEFeyIyJPjeZotLSYTV0nzwR0=";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    mv asdcontrol $out/bin
    runHook postInstall
  '';

  meta = with lib; {
    description = "Apple Studio Display monitor brightness control for Linux.";
    homepage = "https://github.com/nikosdion/asdcontrol";
    longDescription = ''
      A simple program to control the brightness of Apple thunderbolt dipsplays
      (Pro Display XDR, Studio Display) on Linux.
    '';
    license = licenses.gpl2;
    maintainers = with maintainers; [_0xcharly];
    mainProgram = "asdcontrol";
  };
}
