{ self, ... }:
{
  flake.homeModules.programs-password-managers = {
    imports = with self.homeModules; [
      programs-1password
      programs-bitwarden
      programs-proton-pass
    ];

    xdg.mimeApps = {
      associations.added."x-scheme-handler/otpauth" = "bitwarden.desktop";
      defaultApplications."x-scheme-handler/otpauth" = "bitwarden.desktop";
    };
  };
}
