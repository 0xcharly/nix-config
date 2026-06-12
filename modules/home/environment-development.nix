{
  flake.homeModules.environment-development =
    { lib, pkgs, ... }:
    {
      home.packages = with pkgs; [
        devenv # Development environment management
        git-get # Repository management
      ];

      programs.fish.interactiveShellInit = ''
        ${lib.getExe pkgs.devenv} hook fish | source
      '';
    };
}
