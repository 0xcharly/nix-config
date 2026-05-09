{
  flake.homeModules.programs-beeper =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.beeper ];
    };
}
