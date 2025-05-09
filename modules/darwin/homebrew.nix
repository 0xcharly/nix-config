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
        ColorSlurp = 1287239339;
      }
      // (lib.optionalAttrs (!isCorpManaged) {
        Amphetamine = 937984704;
        "Pixelmator Pro" = 1289583905;
        Xcode = 497799835; # Xcode is installed out-of-band on corp devices.
      });
    casks = let
      no_quarantine = name: {
        inherit name;
        args.no_quarantine = true;
      };
    in
      [
        # Cross-platforms password management.
        "1password"
        "proton-pass"

        # Browsers.
        (no_quarantine "eloston-chromium") # Ungoogled Chromium.
        "firefox@developer-edition" # Firefox, for isolates.
        "google-chrome" # When there's no alternatives.

        # Utilities.
        "beeper" # Messaging.
        "ghostty" # Terminal.
        "obsidian" # Note taking.
        "raycast" # Mandatory Spotlight alternative.
        "scroll-reverser" # Custom scroll directions for trackpad vs. mouse.
        "spotify" # Because the web version sucks.
        "tidal" # Spotify alternative.
      ]
      ++ (lib.optionals (!isCorpManaged) [
        # Don't install these on corp-managed hosts.
        "protonvpn" # Private network.
        "tailscale" # Personal VPN network.
        "transmission"
        "vlc" # Media player.
      ]);
  };
}
