{
  flake.homeModules.programs-nautilus =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.nautilus ];
    };
}
