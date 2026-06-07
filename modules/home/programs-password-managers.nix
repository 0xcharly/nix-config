{ self, ... }:
{
  flake.homeModules.programs-password-managers = {
    imports = with self.homeModules; [
      programs-1password
      # # TODO(26.11): bitwarden-desktop package is broken
      # programs-bitwarden
      programs-proton-pass
    ];

    xdg.mimeApps = {
      associations.added."x-scheme-handler/otpauth" = "proton-pass.desktop";
      defaultApplications."x-scheme-handler/otpauth" = "proton-pass.desktop";
    };
  };
}
