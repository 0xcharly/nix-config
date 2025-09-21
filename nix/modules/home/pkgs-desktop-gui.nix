{pkgs, ...}: {
  home.packages = with pkgs; [
    _1password-gui
    beeper
    bitwarden
    localsend
    nautilus
    obsidian
    tidal-hifi
    xfce.thunar
  ];

  programs.zathura.enable = true; # PDF viewer.

  xdg.mimeApps.defaultApplications = {
    "application/pdf" = ["org.pwmt.zathura.desktop"];
  };
}
