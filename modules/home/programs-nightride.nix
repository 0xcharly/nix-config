# Synthwave TUI streamer for nightride.fm; playback via wrapped mpv.
{ moduleWithSystem, ... }:
{
  flake.homeModules.programs-nightride = moduleWithSystem (
    perSystem@{ config, ... }:
    { ... }:
    {
      home.packages = [ perSystem.config.packages.nightride ];
    }
  );

  perSystem =
    { pkgs, ... }:
    {
      packages.nightride = pkgs.callPackage ./nightride { };
    };
}
