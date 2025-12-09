{flake, ...}: {pkgs, ...}: let
  pkgs' = flake.lib.pkgs.mkUnstablePkgs pkgs;
in {
  home.packages = [
    pkgs.bluetui
    # TODO(25.11): install wiremix from the stable channel.
    pkgs'.wiremix # Not available on the stable channel yet.
  ];
}
