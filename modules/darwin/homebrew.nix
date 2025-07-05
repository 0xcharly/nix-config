{
  config,
  lib,
  ...
}: let
  inherit (config.modules.usrenv) isCorpManaged;
in {
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
    };
    global = {
      brewfile = true;
      autoUpdate = false;
    };
    masApps =
      {
        Amphetamine = 937984704;
        ColorSlurp = 1287239339;
      }
      // lib.optionalAttrs (!isCorpManaged) {
        Xcode = 497799835; # Xcode is installed out-of-band on corp devices.
      };
    casks = let
      no_quarantine = name: {
        inherit name;
        args.no_quarantine = true;
      };
    in
      [
        # Cross-platforms password management.
        "1password"
        "1password-cli"
        "proton-pass"

        # Browsers.
        "firefox@developer-edition" # Firefox, for isolates.

        # Utilities.
        "beeper" # Messaging.
        "ghostty" # Terminal.
        "raycast" # Mandatory Spotlight alternative.
        "tidal" # Spotify alternative.
        "vlc" # Media player.
      ]
      ++ lib.optionals (!isCorpManaged) [
        # Don't install these on corp-managed hosts.
        "google-chrome" # When there's no alternatives.
        "protonvpn" # Private network.
        "tailscale-app" # Personal VPN network.
        "transmission"
      ];
  };
}
