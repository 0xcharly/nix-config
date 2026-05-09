{
  flake.homeModules.opencode =
    { pkgs', ... }:
    {
      programs.opencode = {
        enable = true;
        package = pkgs'.opencode;
      };
    };
}
