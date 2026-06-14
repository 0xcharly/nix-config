{
  lib,
  stdenv,
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
  ninja,
}:
let
  version = "0.0.1";

  runtimeInputs = [
    apdbctl
    brightnessctl
    ddcutil
    hyprland
    networkmanager
  ];

  fontconfig = makeFontsConf {
    fontDirectories = [
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
