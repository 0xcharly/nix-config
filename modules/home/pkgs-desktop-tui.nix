{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bluetui
    mplayer # Remember QF60…
    wiremix
  ];
}
