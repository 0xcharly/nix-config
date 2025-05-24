{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./browsers.nix
    ./catppuccin.nix
    ./fonts.nix
    ./hyprland.nix
    ./linux-desktop.nix
    ./multiplexers.nix
    ./nix-client-config.nix
    ./nixos.nix
    ./packages.nix
    ./raycast.nix
    ./scripts.nix
    ./shells.nix
    ./ssh.nix
    ./systemd-timers.nix
    ./terminals.nix
    ./vcs.nix
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
