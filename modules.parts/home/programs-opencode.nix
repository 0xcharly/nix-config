{
  flake.homeModules.programs-opencode =
    { pkgs', ... }:
    {
      programs.opencode = {
        enable = true;
        package = pkgs'.opencode;
      };
    };
}
