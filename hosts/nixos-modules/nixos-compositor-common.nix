{globalModules, ...}: {
  imports = with globalModules; [fonts];

  # Required for graphical interfaces (X or Wayland) to work.
  security.polkit.enable = true;

  environment.etc = {
    "xdg/gtk-2.0/gtkrc".text = ''
      gtk-application-prefer-dark-theme=1
      gtk-error-bell=0
    '';
    "xdg/gtk-3.0/settings.ini".text = ''
      [Settings]
      gtk-application-prefer-dark-theme=1
      gtk-error-bell=false
    '';
    "xdg/gtk-4.0/settings.ini".text = ''
      [Settings]
      gtk-application-prefer-dark-theme=1
      gtk-error-bell=false
    '';
  };
}
