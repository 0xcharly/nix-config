{
  config,
  lib,
  ...
}: let
  inherit (config.settings) isCorpManaged;
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
        "1Password for Safari" = 1569813296;
        "Adguard for Safari" = 1440147259;
        "Amphetamine" = 937984704;
        "DarkReader for Safari" = 1438243180;
        "Pixelmator Pro" = 1289583905;
      }
      // (lib.optionalAttrs (!isCorpManaged) {
        Xcode = 497799835;
      });
    casks =
      [
        "1password"
        "1password-cli"
        "discord"
        "firefox"
        "firefox@developer-edition"
        #"monodraw"
        "messenger"
        "mimestream"
        "notion"
        "notion-calendar"
        "proton-mail"
        "prusaslicer"
        "raycast"
        "spotify"
        "vlc"
      ]
      ++ (lib.optionals (!isCorpManaged) [
        "google-chrome"
        "protonvpn"
        "transmission"
      ]);
  };
}
