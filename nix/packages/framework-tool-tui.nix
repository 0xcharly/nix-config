{
  pkgs,
  pname,
  ...
}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    inherit pname;
    version = "0.5.1";

    src = fetchFromGitHub {
      owner = "grouzen";
      repo = "framework-tool-tui";
      tag = "v${version}";
      sha256 = "sha256-R4/VeymmthI96PJt7XsKRYz1Y8QW/lV90HvJgt+e+hI=";
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

    cargoHash = "sha256-tDNYkV5MWb4+co/gwjpAt/M7yJbEWrryieJoBuXmY8M=";

    doInstallCheck = true;
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
