{pkgs, ...} @ args: let
  config =
    if args ? osConfig
    then args.osConfig
    else args.config;
  inherit (pkgs.stdenv) isLinux;
  inherit (config.modules.usrenv) isHeadless;

  enable = isLinux && !isHeadless;
in {
  home.packages = [pkgs.vanilla-dmz];

  dconf = {
    inherit enable;
    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        # Defaulting to Vanilla-DMZ because of a GTK4 bug that breaks the cursor rendering:
        # https://bbs.archlinux.org/viewtopic.php?id=299624
        cursor-theme = "vanilla-dmz";
        # cursor-theme = "catppuccin-mocha-dark-cursors";
        # cursor-size = 24;
      };
    };
  };
}
