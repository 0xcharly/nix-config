{ pkgs, ... }:
{
  home.packages = with pkgs; [
    _1password-gui
    bitwarden-desktop
    nautilus
    xfce.thunar
  ];

  programs.zathura.enable = true; # PDF viewer.

  xdg.mimeApps = {
    enable = true;
    associations.added = {
      "application/pdf" = "org.pwmt.zathura.desktop";
      "x-scheme-handler/otpauth" = "bitwarden.desktop";
    };
    defaultApplications = {
      "application/pdf" = "org.pwmt.zathura.desktop";
      "x-scheme-handler/otpauth" = "bitwarden.desktop";
    };
  };
}
