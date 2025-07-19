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
        "1password" # Password manager.
        "ghostty" # Terminal.
        "raycast" # Mandatory Spotlight alternative.
      ]
      ++ lib.optionals (!isCorpManaged) [
        # Don't install these on corp-managed hosts.
        "beeper" # Messaging.
        "bitwarden" # Personal password management.
        "firefox@developer-edition" # Firefox, for isolates.
        "google-chrome" # When there's no alternatives.
        "obsidian" # Notes.
        "protonvpn" # Private network.
        "tailscale-app" # Personal VPN network.
        "tidal" # Spotify alternative.
        "transmission"
        "vlc" # Media player.
      ];
  };
}
