{ pkgs, ... }:
{
  home.packages = with pkgs; [
    beeper
    nautilus
  ];
}
