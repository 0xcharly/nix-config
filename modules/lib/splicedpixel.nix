{
  perSystem =
    { pkgs, config, ... }:
    {
      packages.splicedpixel = pkgs.callPackage ./internal/splicedpixel { };

      # Fails when modules/lib/internal/colors/colors.json is stale w.r.t. theme.toml.
      # Regenerate with the `generate-colorscheme` devenv script.
      checks.splicedpixel-colors-json =
        pkgs.runCommand "splicedpixel-colors-json-fresh"
          { nativeBuildInputs = [ config.packages.splicedpixel ]; }
          ''
            splicedpixel render --config ${./internal/colors/theme.toml} --format json > generated.json
            diff -u ${./internal/colors/colors.json} generated.json
            touch $out
          '';
    };
}
