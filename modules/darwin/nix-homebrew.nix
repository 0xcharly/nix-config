{
  config,
  inputs,
  ...
}: {
  # Nix-managed homebrew.
  imports = [inputs.homebrew.darwinModules.nix-homebrew];

  nix-homebrew = {
    enable = true; # Install Homebrew under the default prefix.
    user = config.modules.system.mainUser; # User owning the Homebrew prefix.
  };
}
