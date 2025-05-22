{
  lib,
  pkgs,
  ...
}: {
  # Raycast expects script attributes to be listed at the top of the file,
  # so a simple wrapper does not work. This *needs* to be a symlink.
  xdg.configFile."raycast/bin/scrcpy" = lib.optionalAttrs pkgs.stdenv.isDarwin {
    source = lib.getExe pkgs.raycast-scrcpy;
  };
}
