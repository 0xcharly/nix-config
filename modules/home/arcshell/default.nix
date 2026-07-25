{
  lib,
  stdenv,
  stdenvNoCC,
  fetchFromGitHub,
  writeText,
  makeWrapper,
  apdbctl,
  brightnessctl,
  ddcutil,
  hyprland,
  libnotify,
  material-symbols,
  networkmanager,
  systemd,
  tailscale,
  uwsm,
  nerd-fonts,
  qt6,
  quickshell,
  cmake,
  curl,
  ninja,
}:
let
  version = "0.0.1";

  # Quickshell 0.3.0's NetworkManager wrapper segfaults when an access
  # point disappears while a wifi network still references it (use-after-
  # free in the AP/settings destroy handlers; reliably triggered by scan
  # churn while the wifi selector is open). Cherry-pick of upstream
  # ead3b00afdf603bb6d4c30fc9c9f582d8f712168 — drop the patch and this
  # override when updating past 0.3.0.
  quickshell' = quickshell.overrideAttrs (prev: {
    patches = (prev.patches or [ ]) ++ [
      ./patches/0001-networking-fix-uafs-in-nmwirelessnetwork-destroy-handlers.patch
    ];
  });

  runtimeInputs = [
    apdbctl
    brightnessctl
    curl
    ddcutil
    hyprland
    libnotify
    networkmanager
    systemd
    tailscale
    uwsm
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

  # Overlay the bundled glyph fonts (icons, Doto) on top of the host
  # fontconfig instead of replacing it: generic families ("monospace",
  # "sans-serif", "serif") in the QML tokens then resolve through the
  # session's fontconfig preferences (fonts.fontconfig.defaultFonts, driven
  # by modules/lib/fonts.toml), while the shell's bespoke glyph fonts are
  # guaranteed regardless of what the user installs.
  fontconfig = writeText "arc-shell-fonts.conf" ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <include ignore_missing="yes">/etc/fonts/fonts.conf</include>
      <dir>${doto}/share/fonts</dir>
      <dir>${material-symbols}/share/fonts</dir>
      <dir>${nerd-fonts.symbols-only}/share/fonts</dir>
      <cachedir prefix="xdg">fontconfig</cachedir>
    </fontconfig>
  '';

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
    quickshell'
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
    makeWrapper ${quickshell'}/bin/qs $out/bin/arc-shell \
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
