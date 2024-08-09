{
  globalModules,
  sharedModules,
  ...
}: {
  imports =
    (with sharedModules; [
      aarch64-darwin
      homebrew
      macos
      nix-homebrew
      nix-index
    ])
    ++ (with globalModules; [fonts nix-client-config]);

  settings.compositor = "quartz";

  # Mark admins as trusted users to enable cachix repositories.
  nix.settings.trusted-users = ["@admin"];

  # We install Nix using a separate installer so we don't want nix-darwin
  # to manage it for us. This tells nix-darwin to just use whatever is running.
  nix.useDaemon = true;

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
}
