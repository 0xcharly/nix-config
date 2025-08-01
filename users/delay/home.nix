{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./browsers.nix
    ./catppuccin.nix
    ./fonts.nix
    ./launcher.nix
    ./linux-desktop.nix
    ./multiplexers.nix
    ./nixos.nix
    ./packages.nix
    ./raycast.nix
    ./shells.nix
    ./ssh.nix
    ./systemd-timers.nix
    ./terminals.nix
    ./vcs.nix
    ./wayland.nix
    ./wayland-hyprland.nix
    ./wayland-sway.nix
  ];

  home.sessionVariables = let
    nvim = lib.getExe pkgs.nvim;
  in {
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    EDITOR = nvim;
    VISUAL = nvim;
    MANPAGER = "${nvim} +Man!";
    PAGER = "less -FirSwX";
  };
}
