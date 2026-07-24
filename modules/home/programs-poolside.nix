# Bespoke retro TUI streamer for Poolside FM (radio.co); playback via
# wrapped mpv.
{ moduleWithSystem, ... }:
{
  flake.homeModules.programs-poolside = moduleWithSystem (
    perSystem@{ config, ... }:
    { ... }:
    {
      home.packages = [ perSystem.config.packages.poolside ];
    }
  );

  perSystem =
    { pkgs, ... }:
    {
      packages.poolside = pkgs.callPackage ./poolside { };
    };
}
