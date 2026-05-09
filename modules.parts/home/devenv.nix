{
  flake.homeModules.devenv =
    {
      config,
      pkgs,
      pkgs',
      ...
    }:
    {
      home.packages = [
        pkgs'.devenv # Development environment management
        pkgs.git-get # Repository management
      ];

      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        config = {
          warn_timeout = 0;
          whitelist.prefix = [ "${config.home.homeDirectory}/code" ];
        };
      };
    };
}
