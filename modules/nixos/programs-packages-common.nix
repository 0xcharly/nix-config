{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    gnumake
    killall
    rxvt-unicode-unwrapped
    tmux
  ];

  # Don't need to wait 1+s on a typo.
  programs.command-not-found.enable = false;
}
