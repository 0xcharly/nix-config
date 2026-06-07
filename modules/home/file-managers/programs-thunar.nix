{
  flake.homeModules.programs-thunar =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.thunar ];
    };
}
