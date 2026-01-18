{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    ghostty.terminfo
    kitty.terminfo
  ];
}
