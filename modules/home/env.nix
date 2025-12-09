{
  lib,
  pkgs,
  ...
}: {
  home.sessionVariables = let
    nvim = lib.getExe pkgs.nvim;
  in {
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    EDITOR = nvim;
    VISUAL = nvim;
    MANPAGER = "${nvim} +Man!";
    PAGER = "less -FirSwX";
  };
}
