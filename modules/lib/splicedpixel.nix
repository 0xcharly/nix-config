{
  perSystem =
    { pkgs, config, ... }:
    {
      packages.splicedpixel = pkgs.callPackage ./_splicedpixel { };

      # Fails when modules/lib/_colors/colors.json is stale w.r.t. theme.toml.
      # Regenerate with the `generate-colorscheme` devenv script.
      checks.splicedpixel-colors-json =
        pkgs.runCommand "splicedpixel-colors-json-fresh"
          { nativeBuildInputs = [ config.packages.splicedpixel ]; }
          ''
            splicedpixel render --config ${./_colors/theme.toml} --format json > generated.json
            diff -u ${./_colors/colors.json} generated.json
            touch $out
          '';
    };
}
