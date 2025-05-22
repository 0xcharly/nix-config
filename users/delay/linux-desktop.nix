{
  pkgs,
  pkgs',
  lib,
  usrlib,
  ...
} @ args: let
  inherit ((usrlib.hm.getUserConfig args).modules.usrenv) isLinuxDesktop;
in
  lib.mkIf isLinuxDesktop {
    home.packages = with pkgs; [
      pkgs'._1password-gui
      beeper
      localsend
      nautilus
      obsidian
      proton-pass
      tidal-hifi
      xfce.thunar
    ];

    services.udiskie.enable = true; # USB automount (requires udisks2 service enabled).
    programs.zathura.enable = true; # PDF viewer.

    xdg.mimeApps = {
      defaultApplications = {
        "application/pdf" = ["org.pwmt.zathura.desktop"];
      };
    };

    dconf = {
      enable = true;
      settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          font-name = "Recursive Sans Casual Static 12";
          monospace-font-name = "Recursive Mono Casual Static 13";
          document-font-name = "Recursive Sans Casual Static 12";
        };
        "org/gtk/settings/file-chooser" = {
          sort-directories-first = true;
        };
      };
    };

    gtk = {
      enable = true;
      # Adwaita should be the default, but setting it explicitly breaks it (i.e.
      # force light-mode).
      # theme.name = "Adwaita";
      iconTheme = {
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
      };
      font = {
        name = "Recursive Sans Casual Static";
        size = 12;
      };
      gtk2.extraConfig = ''
        gtk-application-prefer-dark-theme=1
      '';
      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
    };

    xdg.configFile."gtk-4.0/settings.ini".text = ''
      [AdwStyleManager]
      color-scheme=ADW_COLOR_SCHEME_PREFER_DARK
    '';

    qt = {
      enable = true;
      platformTheme.name = "adwaita";
      style = {
        name = "adwaita-dark";
        package = pkgs.adwaita-qt;
      };
    };

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [xdg-desktop-portal-gtk];
      config = {
        common = {
          default = ["gtk" "wlr"];
        };
        Hyprland = {
          default = ["hyprland" "gtk" "wlr"];
        };
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
