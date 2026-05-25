{
  flake.homeModules.services-bluetooth =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        bluetui
      ];
    };
}
