{ flake, ... }:
{ pkgs, ... }:
let
  inherit (flake.lib.user.gui.fonts) monospace sansSerif;
  inherit (flake.lib.fonts) mkFontName;
in
{
  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        document-font-name = mkFontName sansSerif;
        font-name = mkFontName sansSerif;
        monospace-font-name = mkFontName monospace;
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
    font = { inherit (sansSerif) name size; };
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

  home.pointerCursor = {
    name = "BreezeX-RosePine-Linux";
    package = pkgs.rose-pine-cursor;
    size = 32;
    gtk.enable = true;
    x11.enable = true;
  };
}
