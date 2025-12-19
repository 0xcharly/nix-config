{pkgs, ...}: {
  home.packages = with pkgs; [
    _1password-gui
    bitwarden-desktop
    blueberry
    nautilus
    obsidian
    proton-pass
    xfce.thunar
  ];

  programs.zathura.enable = true; # PDF viewer.

  xdg.mimeApps.defaultApplications = {
    "application/pdf" = ["org.pwmt.zathura.desktop"];
  };
}
