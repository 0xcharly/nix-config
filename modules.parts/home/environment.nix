{ withSystem, ... }:
{
  flake.homeModules.environment =
    { lib, pkgs, ... }:
    {
      home.sessionVariables =
        let
          nvim = lib.getExe (
            withSystem pkgs.stdenv.hostPlatform.system ({ config, ... }: config.packages.nvim)
          );
        in
        {
          LANG = "en_US.UTF-8";
          LC_ALL = "en_US.UTF-8";
          LC_CTYPE = "en_US.UTF-8";
          EDITOR = nvim;
          VISUAL = nvim;
          MANPAGER = "${nvim} +Man!";
          PAGER = "less -FirSwX";
        };
    };
}
