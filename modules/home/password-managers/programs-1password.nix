{
  flake.homeModules.programs-1password =
    { pkgs, ... }:
    {
      home.packages = [ pkgs._1password-gui ];
    };
}
