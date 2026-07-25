{ lib, fonts }:
let
  # A role is either a preset id (string) or { preset = "<id>", ... }
  # where extra attributes override the preset.
  resolveRole =
    role:
    let
      spec =
        if lib.isString role then
          fonts.preset.${role}
        else
          fonts.preset.${role.preset} // removeAttrs role [ "preset" ];
    in
    {
      inherit (spec) name size;
      # Stylistic sets and character variants are just OpenType features;
      # renderers consume one merged list.
      features = (spec.features or [ ]) ++ (spec.stylisticSets or [ ]) ++ (spec.characterVariants or [ ]);
      variations = spec.variations or { };
    };

  # font.{terminal,monospace,sansSerif,serif,emoji,cjk} ::
  #   { name, size, features :: [str], variations :: attrs }
  font = lib.mapAttrs (_: resolveRole) (removeAttrs fonts [ "preset" ]);
in
{
  colors = import ./colors { inherit lib; };

  inherit font;

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
      # A section whose key names a role in fonts.toml (e.g. `cjk`) renders
      # in that role's font; otherwise the section's own font_name applies.
      transformMappingValue =
        key:
        {
          font_name ? "default",
          codepoints,
          ...
        }:
        lib.nameValuePair (font.${key}.name or font_name) (lib.concatStringsSep "," codepoints);
      rehydrateMappings = lib.mapAttrs' transformMappingValue;
    in
    lib.mapAttrsToList fn (rehydrateMappings mappings);
}
