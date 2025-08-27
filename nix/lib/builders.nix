{
  mkShellApplication = pkgs: opts:
    pkgs.lib.getExe (pkgs.writeShellApplication opts);
}
