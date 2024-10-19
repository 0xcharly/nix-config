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
        # Cross-platfroms password management.
        "1password"

        # Browsers.
        # https://chromium.googlesource.com/chromium/src/+/main/docs/mac_arm64.md
        (no_quarantine "chromium")
        # https://librewolf.net/docs/faq/#why-is-librewolf-marked-as-broken
        (no_quarantine "librewolf")
        "firefox@developer-edition"
        "orion"

        # Utilities.
        "raycast" # Mandatory Spotlight alternative.
        "scroll-reverser" # Custom scroll directions for trackpad vs. mouse.
        "spotify" # Because the web version sucks.
        "tidal" # Spotify alternative.
      ]
      ++ (lib.optionals (!isCorpManaged) [
        # Don't install these on corp-managed hosts.
        "protonvpn"
        "transmission"
      ]);
  };
}
