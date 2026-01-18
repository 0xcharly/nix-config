{ flake, ... }:
{ pkgs, ... }:
{
  programs.opencode = {
    enable = true;
    package = (flake.lib.pkgs.mkUnstablePkgs pkgs).opencode;
  };
}
