username: {
  pkgs,
  lib,
  ...
}: {
  # For-user Home Manager configurations.
  imports = [
    ./${username}/home.nix

    # Additional configuration that should be set for any existing and future
    # users declared in this module. Any "shared" configuration between users
    # may be passed here.
    {
      # Required to generate `~/.config/nix/nix.conf`.
      nix.package = pkgs.nix;

      # The state version indicates which default settings are in effect and
      # will therefore help avoid breaking program configurations.
      home.stateVersion = lib.mkDefault "24.05";

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
  ];
}
