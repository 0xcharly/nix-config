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
        "Amphetamine" = 937984704;
        "ColorSlurp" = 1287239339;
        "Pixelmator Pro" = 1289583905;
      }
      // (lib.optionalAttrs (!isCorpManaged) {
        # Xcode is installed out-of-band on corp devices.
        Xcode = 497799835;
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

        # Utilities.
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
        "raspberry-pi-imager" # RPI bootloader & OS images.
        "tailscale" # Personal VPN network.
        "transmission"
        "vlc" # Media player.
      ]);
  };
}
