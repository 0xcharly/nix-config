# Vendored from nixpkgs pkgs/by-name/io/iosevka-bin/package.nix, modified to
# fetch the SuperTTC bundle (a single .ttc collecting the whole family)
# instead of the PkgTTC archive.
# https://github.com/be5invis/Iosevka/blob/main/doc/PACKAGE-LIST.md
{
  stdenv,
  lib,
  fetchurl,
  iosevka,
  unzip,
  variant ? "",
}:

let
  name = if lib.hasPrefix "SGr-" variant then variant else "Iosevka" + variant;

  # SuperTTC zip hashes, keyed by family name. Add entries here to support
  # more variants. The version tracks pkgs.iosevka (the source builder used
  # for the custom flavors) so both stay in sync; a nixpkgs bump makes these
  # hashes mismatch loudly — refresh them with
  #   nix store prefetch-file https://github.com/be5invis/Iosevka/releases/download/v<V>/SuperTTC-<name>-<V>.zip
  variantHashes = {
    Iosevka = "sha256-JPfI5vh0A3qlHW6dKXB1VBfP9ahFdQ5lAlEjDVE7Syc=";
    IosevkaEtoile = "sha256-A/ej5HlBhdJFIEC9KfAHpCfDMSEtVpC9oC2FBsEzaK0=";
  };
  validVariants = map (lib.removePrefix "Iosevka") (
    builtins.attrNames (removeAttrs variantHashes [ "Iosevka" ])
  );
in
stdenv.mkDerivation (finalAttrs: {
  pname = "${name}-bin";
  version = iosevka.version;

  src = fetchurl {
    url = "https://github.com/be5invis/Iosevka/releases/download/v${finalAttrs.version}/SuperTTC-${name}-${finalAttrs.version}.zip";
    hash =
      variantHashes.${name} or (throw ''
        No such variant "${variant}" for package iosevka.
        Valid variants are: ${lib.concatStringsSep ", " validVariants}.
      '');
  };

  nativeBuildInputs = [ unzip ];

  dontInstall = true;

  unpackPhase = ''
    mkdir -p $out/share/fonts
    unzip -d $out/share/fonts/truetype $src
  '';

  meta = {
    inherit (iosevka.meta)
      homepage
      downloadPage
      description
      license
      platforms
      ;
  };
})
