{
  flake.homeModules.environment =
    { config, lib, ... }:
    {
      home.sessionVariables =
        let
          nvim = lib.getExe config.my.programs.nvim.package;
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
