{
  lib,
  pkgs,
  ...
}: {
  # Raycast expects script attributes to be listed at the top of the file,
  # so a simple wrapper does not work. This *needs* to be a symlink.
  xdg = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    configFile."raycast/bin/scrcpy".source = lib.getExe pkgs.raycast-scrcpy;
  };
}
