{
  perSystem =
    { pkgs, config, ... }:
    {
      packages.splicedpixel-vscode = pkgs.callPackage ./internal/splicedpixel-vscode {
        inherit (config.packages) splicedpixel;
      };
    };
}
