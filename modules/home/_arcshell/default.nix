{
  lib,
  stdenv,
  stdenvNoCC,
  fetchFromGitHub,
  makeFontsConf,
  makeWrapper,
  apdbctl,
  brightnessctl,
  ddcutil,
  hyprland,
  recursive,
  material-symbols,
  networkmanager,
  nerd-fonts,
  qt6,
  quickshell,
  cmake,
  curl,
  ninja,
}:
let
  version = "0.0.1";

  runtimeInputs = [
    apdbctl
    brightnessctl
    curl
    ddcutil
    hyprland
    networkmanager
  ];

  # A bitmap inspired, open-source, variable, monospace, geometric typeface.
  doto = stdenvNoCC.mkDerivation {
    pname = "doto";
    version = "0-unstable-2024-10-06";

    src = fetchFromGitHub {
      owner = "oliverlalan";
      repo = "Doto";
      rev = "1c587f2eed62cb257055540ac2a15f356070414f";
      hash = "sha256-ECcTx/qMZWr5iF6X5iouKV1tUt0xRCcoQUwma3FP7jU=";
    };

    installPhase = ''
      runHook preInstall
      install -Dm644 "fonts/variable/Doto[ROND,wght].ttf" -t "$out/share/fonts/truetype"
      runHook postInstall
    '';

    meta.license = lib.licenses.ofl;
  };

  fontconfig = makeFontsConf {
    fontDirectories = [
      doto
      material-symbols
      nerd-fonts.symbols-only
      recursive
    ];
  };

  cmakeVersionFlags = [
    (lib.cmakeFeature "VERSION" version)
  ];
in
stdenv.mkDerivation {
  inherit version;
  pname = "arc-shell";
  src = ./.;

  nativeBuildInputs = [
    cmake
    ninja
    makeWrapper
    qt6.wrapQtAppsHook
  ];
  buildInputs = [
    quickshell
    qt6.qtbase
  ];
  propagatedBuildInputs = runtimeInputs;

  passthru = { inherit doto; };

  cmakeFlags = [
    (lib.cmakeFeature "ENABLE_MODULES" "shell")
    (lib.cmakeFeature "INSTALL_QSCONFDIR" "${placeholder "out"}/share/arc-shell")
  ]
  ++ cmakeVersionFlags;

  prePatch = ''
    substituteInPlace shell.qml \
      --replace-fail 'ShellRoot {' 'ShellRoot {  settings.watchFiles: false'
  '';

  postInstall = ''
    makeWrapper ${quickshell}/bin/qs $out/bin/arc-shell \
    	--prefix PATH : "${lib.makeBinPath runtimeInputs}" \
    	--set FONTCONFIG_FILE "${fontconfig}" \
    	--add-flags "-p $out/share/arc-shell"
  '';

  meta = {
    description = "A bespoke desktop shell";
    homepage = "https://github.com/0xcharly/nix-config-shell";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ _0xcharly ];
    mainProgram = "arc-shell";
  };
}
