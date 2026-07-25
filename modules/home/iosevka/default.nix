# Iosevka built from source so the character-variant selection below is baked
# into the default glyphs, instead of being selected at runtime through
# `cvNN=k` font features.
#
# Runtime selection cannot work for a list this size: HarfBuzz packs all
# features of a shaping run into a single 32-bit per-glyph mask, and a value'd
# feature `cvNN=k` reserves ceil(log2(k+1)) bits. This list needs ~130 bits,
# so HarfBuzz silently drops whichever features no longer fit — the same
# reason every HarfBuzz consumer (kitty, ghostty, ...) appeared to "ignore"
# random character variants.
#
# Variant names come from the customizer; the build fails on unknown names.
# https://typeof.net/Iosevka/customizer
# https://github.com/be5invis/Iosevka/blob/v34.4.0/doc/character-variants.md
{
  iosevka,
  set,
  family,
  spacing,
}:
iosevka.override {
  inherit set;
  privateBuildPlan = {
    inherit family spacing;
    serifs = "sans";

    variants.design = {
      five = "oblique-arched-serifless";
      six = "straight-bar";
      seven = "curly-serifed";
      nine = "straight-bar";
      zero = "slashed-cutout";
      capital-b = "standard-unilateral-serifed";
      capital-c = "unilateral-inward-serifed";
      capital-d = "standard-unilateral-serifed";
      capital-e = "top-left-serifed";
      capital-f = "top-left-serifed";
      capital-g = "toothless-corner-inward-serifed-hooked";
      capital-h = "top-left-serifed";
      capital-i = "short-serifed";
      capital-k = "straight-top-left-serifed";
      capital-l = "motion-serifed";
      capital-m = "hanging-motion-serifed";
      capital-n = "standard-motion-serifed";
      capital-p = "closed-motion-serifed";
      capital-q = "straight";
      capital-r = "straight-top-left-serifed";
      capital-s = "unilateral-inward-serifed";
      capital-u = "toothed-serifless";
      capital-v = "straight-motion-serifed";
      capital-w = "straight-motion-serifed";
      capital-z = "straight-top-serifed";
      a = "single-storey-top-cut-serifless";
      b = "toothed-motion-serifed";
      c = "unilateral-inward-serifed";
      g = "double-storey";
      h = "straight-top-left-serifed";
      i = "hooky";
      j = "flat-hook-serifed";
      k = "straight-top-left-serifed";
      l = "semi-tailed";
      p = "earless-corner-serifless";
      q = "earless-corner-straight-serifless";
      r = "corner-hooked-serifless";
      s = "unilateral-inward-serifed";
      t = "flat-hook-short-neck";
      z = "straight-top-serifed";
      ellipsis-density = "dense";
      guillemet = "straight";
      number-sign = "slanted";
      ampersand = "upper-open";
      at = "threefold-solid-inner";
      dollar = "slanted-open";
      cent = "slanted-open";
    };

    # Only the faces actually used; the default plan's 54 faces (9 weights x
    # 2 widths x 3 slopes) take hours to build.
    weights = {
      Regular = {
        shape = 400;
        menu = 400;
        css = 400;
      };
      Bold = {
        shape = 700;
        menu = 700;
        css = 700;
      };
    };
    slopes = {
      Upright = {
        angle = 0;
        shape = "upright";
        menu = "upright";
        css = "normal";
      };
      Italic = {
        angle = 9.4;
        shape = "italic";
        menu = "italic";
        css = "italic";
      };
    };
    widths.Normal = {
      shape = 500;
      menu = 5;
      css = "normal";
    };
  };
}
