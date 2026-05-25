{
  flake.homeModules.programs-proton-pass =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.proton-pass ];
    };
}
