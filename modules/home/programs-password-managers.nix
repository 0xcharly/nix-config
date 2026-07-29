{
  flake.homeModules.programs-password-managers = {
    # imports = with self.homeModules; [
    #   NOTE: 1password is installed at the NixOS level for polkit integration.
    #   programs-1password
    #   NOTE: do not install these app wrappers as they depend on electron
    #   NOTE: bitwarden-desktop package is broken in 26.05
    #   programs-bitwarden
    #   programs-proton-pass
    # ];

    xdg.mimeApps = {
      associations.added."x-scheme-handler/otpauth" = "1password.desktop";
      defaultApplications."x-scheme-handler/otpauth" = "1password.desktop";
    };
  };
}
