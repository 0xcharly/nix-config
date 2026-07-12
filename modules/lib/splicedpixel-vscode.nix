{
  perSystem =
    { pkgs, config, ... }:
    {
      packages.splicedpixel-vscode = pkgs.callPackage ./_splicedpixel-vscode {
        inherit (config.packages) splicedpixel;
      };
    };
}
