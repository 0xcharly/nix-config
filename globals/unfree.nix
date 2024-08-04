{
  pkgs,
  lib,
  ...
}: {
  nixpkgs.config.allowUnfreePredicate = pkg:
    pkgs.stdenv.isDarwin
    && (builtins.elem (lib.getName pkg) [
      "1password-cli"
    ]);
}
