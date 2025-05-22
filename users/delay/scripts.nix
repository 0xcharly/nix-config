{
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv) isDarwin;
in {
  home.packages = [
    (pkgs.writeShellScriptBin "term-capabilities" (builtins.readFile ./bin/term-capabilities.sh))
    (pkgs.writeShellScriptBin "term-truecolors" (builtins.readFile ./bin/term-truecolors.sh))
  ];

  # Raycast expects script attributes to be listed at the top of the file,
  # so a simple wrapper does not work. This *needs* to be a symlink.
  xdg.configFile = lib.optionalAttrs isDarwin {
    "raycast/bin/scrcpy".source = lib.getExe pkgs.raycast-scrcpy;
  };
}
