username: {
  pkgs,
  lib,
  ...
}: {
  # For-user Home Manager configurations.
  imports = [
    {
      options.isNixOS = lib.options.mkOption {
        type = lib.types.bool;
        default = false;
        readOnly = true;
        description = ''
          A flag allowing to distinguish between HM running on NixOS and
          standalone HM setups.
        '';
      };
    }

    ./${username}/home.nix

    # Additional configuration that should be set for any existing and future
    # users declared in this module. Any "shared" configuration between users
    # may be passed here.
    rec {
      # Required to generate `~/.config/nix/nix.conf`.
      nix.package = pkgs.nix;

      # Ensure Nix is in the path.
      home.packages = [nix.package];

      # The state version indicates which default settings are in effect and
      # will therefore help avoid breaking program configurations.
      home.stateVersion = lib.mkDefault "24.05";

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
  ];
}
