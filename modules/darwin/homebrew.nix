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
    casks =
      [
        # Cross-platfroms password management.
        "1password"

        # Browsers.
        "firefox@developer-edition"
        "orion"

        # Utilities.
        "raycast" # Mandatory Spotlight alternative.
        "scroll-reverser" # Custom scroll directions for trackpad vs. mouse.
        "spotify" # Because the web version sucks.
      ]
      ++ (lib.optionals (!isCorpManaged) [
        # Don't install these on corp-managed hosts.
        "protonvpn"
        "transmission"
      ]);
  };
}
