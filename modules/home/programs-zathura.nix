# PDF viewer
{
  flake.homeModules.programs-zathura = {
    programs.zathura.enable = true;

    xdg.mimeApps = {
      associations.added."application/pdf" = "org.pwmt.zathura.desktop";
      defaultApplications."application/pdf" = "org.pwmt.zathura.desktop";
    };
  };
}
