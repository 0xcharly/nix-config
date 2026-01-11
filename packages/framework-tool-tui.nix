{
  pkgs,
  pname,
  ...
}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    inherit pname;
    version = "0.7.2";

    src = fetchFromGitHub {
      owner = "grouzen";
      repo = "framework-tool-tui";
      tag = "v${version}";
      sha256 = "sha256-N+X6o76Fn0KAqG2MNyR29cDyuh3lLdV20JX8jxHNHjY=";
    };

    nativeBuildInputs = [
      pkg-config
    ];

    buildInputs = [
      udev
    ];

    nativeInstallCheckInputs = [
      versionCheckHook
    ];

    cargoHash = "sha256-vENf1wzXJdtsN+KfuNgtmJLkdfYf+2ULR+VW61dRG+I=";

    doInstallCheck = false; # "The application needs to be run with root privileges." error
    versionCheckProgram = "${placeholder "out"}/bin/${pname}";
    versionCheckProgramArg = "--version";

    meta = with lib; {
      description = "TUI for controlling and monitoring Framework Computers hardware built in Rust";
      platforms = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      homepage = "https://github.com/grouzen/framework-tool-tui";
      license = licenses.mit;
      maintainers = with maintainers; [_0xcharly];
      mainProgram = pname;
    };
  }
