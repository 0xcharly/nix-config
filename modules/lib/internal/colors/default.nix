# Projections over the generated colors.json (see theme.toml for the source
# of truth; regenerate with the `generate-colorscheme` devenv script).
{ lib }:
let
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.strings) concatMapStringsSep;
  inherit (lib.importJSON ./colors.json) name tokens;

  project = f: mapAttrs (_: f) tokens;
  joinRgb = c: concatMapStringsSep ", " toString c.rgb;
in
{
  inherit name;
  noPrefix = project (c: c.hex);
  asHexStrings = project (c: "#${c.hex}");
  asRgbLiterals = project (c: "rgb(${joinRgb c})");
  asRgbaLiterals = project (c: "rgba(${joinRgb c}, 1)");
}
