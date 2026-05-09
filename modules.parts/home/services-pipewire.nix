{
  flake.homeModules.services-pipewire =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        wiremix
      ];
    };
}
