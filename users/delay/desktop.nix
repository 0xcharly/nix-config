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
      proton-pass
      tidal-hifi
    ];

    services.flameshot.enable = true;

    dconf = {
      enable = true;
      settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          font-name = "Recursive Sans Casual Static 12";
          monospace-font-name = "Recursive Mono Casual Static 13";
          document-font-name = "Recursive Sans Casual Static 12";
          cursor-theme = "BreezeX-RosePine-Linux";
          gtk-theme = "rose-pine";
          icon-theme = "rose-pine-icons";
        };
        "org/gtk/settings/file-chooser" = {
          sort-directories-first = true;
        };
      };
    };

    gtk = {
      enable = true;
      theme = {
        package = pkgs.rose-pine-gtk-theme;
        name = "rose-pine";
      };
      iconTheme = {
        package = pkgs.rose-pine-icon-theme;
        name = "rose-pine-icons";
      };
    };

    home.pointerCursor = {
      name = "BreezeX-RosePine-Linux";
      package = pkgs.rose-pine-cursor;
      size = 32;
      gtk.enable = true;
      x11.enable = true;
    };
  }
