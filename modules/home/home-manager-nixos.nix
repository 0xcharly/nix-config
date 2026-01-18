{
  lib,
  osConfig,
  ...
}:
with lib;
{
  # Ensure that HM uses the same Nix package as the system.
  nix.package = mkForce osConfig.nix.package;

  # I don't care about HM news.
  news.display = "silent";

  # Allow HM to manage itself when in standalone mode.
  # This makes the home-manager command available to users.
  programs.home-manager.enable = true;

  # Try to save some space by not installing variants of the home-manager
  # manual. Unlike what the name implies, this section is for home-manager
  # related manpages only, and does not affect whether or not manpages of
  # actual packages will be installed.
  manual = {
    manpages.enable = false;
    html.enable = false;
    json.enable = false;
  };
}
