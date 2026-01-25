{ lib }:
{
  mkFontName =
    {
      name,
      size,
      ...
    }:
    "${name} ${toString size}";

  # mapFontCodepoints :: (font_name :: String -> codepoints :: [ String ] -> Any)
  mapFontCodepoints =
    fn:
    let
      mappings = fromTOML (builtins.readFile ./codepoints.toml);
      transformMappingValue =
        {
          font_name ? "default",
          codepoints,
          ...
        }:
        lib.nameValuePair font_name (lib.concatStringsSep "," codepoints);
      rehydrateMappings = lib.mapAttrs' (_: transformMappingValue);
    in
    rehydrateMappings mappings |> lib.mapAttrsToList fn;
}
