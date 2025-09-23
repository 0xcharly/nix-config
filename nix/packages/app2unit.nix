{
  pkgs,
  pname,
  ...
}:
with pkgs;
  stdenvNoCC.mkDerivation {
    inherit pname;
    version = "git-2025-04-20";

    src = fetchFromGitHub {
      owner = "Vladimir-csp";
      repo = "app2unit";
      rev = "42613bd4c69cd5720114679a52b73b8b5d947678";
      sha256 = "sha256-7Ui2w6Z6gMegKMIckpBmVlb9rZbbqtzbGAUaC1BHZvY=";
    };

    buildInputs = [
      dash
    ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      cp app2unit $out/bin/
      substituteInPlace $out/bin/app2unit \
        --replace-fail "/bin/sh" "${dash}/bin/dash"
      runHook postInstall
    '';

    meta = with lib; {
      description = "Launch Desktop Entries (or arbitrary commands) as Systemd user units, and do it fast.";
      homepage = "https://github.com/Vladimir-csp/app2unit";
      longDescription = ''
        it performs function similar to (and behaves similarly to) uwsm's app subcommand,
        but without costly startup of python interpreter or necessity of having a daemon running for speeding things up.
      '';
      license = licenses.gpl3;
      maintainers = with maintainers; [_0xcharly];
      mainProgram = "app2unit";
    };
  }
