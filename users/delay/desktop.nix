{
  pkgs,
  lib,
  ...
} @ args: let
  config =
    if args ? osConfig
    then args.osConfig
    else args.config;
  inherit (pkgs.stdenv) isLinux;
  inherit (config.modules.usrenv) isHeadless;

  isLinuxDesktop = isLinux && !isHeadless;
in
  lib.mkIf isLinuxDesktop {
    home.packages = with pkgs; [
      element-desktop
      obsidian
      vanilla-dmz
    ];

    services.flameshot.enable = true;

    dconf = {
      enable = true;
      settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          # Defaulting to Vanilla-DMZ because of a GTK4 bug that breaks the cursor rendering:
          # https://bbs.archlinux.org/viewtopic.php?id=299624
          cursor-theme = lib.mkForce "vanilla-dmz";
          # cursor-theme = "catppuccin-mocha-dark-cursors";
          # cursor-size = 24;
        };
      };
    };

    gtk = {
      enable = true;
      theme = {
        package = pkgs.qogir-theme;
        name = "Qogir Dark";
      };
    };
  }
