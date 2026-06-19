{ lib }:
let
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.strings) concatStringsSep;
  inherit (lib.trivial) id;

  transformColorValues =
    format: transform:
    let
      fn = mapAttrs (_: transform);
      palettes = mapAttrs (_: fn) {
        blends = import ./blends-palette-${format}.nix;
        others = import ./others-palette-${format}.nix;
        tailwind = import ./tailwind-palette-${format}.nix;
      };
    in
    import ./colors.nix palettes;
in
{
  name = "pixel";
  noPrefix = transformColorValues "hex" id;
  asHexLiterals = transformColorValues "hex" (value: "0x${value}");
  asHexStrings = transformColorValues "hex" (value: "#${value}");
  asRgbLiterals = transformColorValues "rgb" (
    value: "rgb(${map toString value |> concatStringsSep ", "})"
  );
  asRgbaLiterals = transformColorValues "rgba" (
    value: "rgba(${map toString value |> concatStringsSep ", "})"
  );
  asOklchLiterals = transformColorValues "oklch" (
    value: "oklch(${map toString value |> concatStringsSep ", "})"
  );
}
