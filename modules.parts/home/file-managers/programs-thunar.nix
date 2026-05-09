{
  flake.homeModules.programs-thunar =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.xfce.thunar ];
    };
}
