{
  isCorpManaged,
  lib,
  pkgs,
  ...
}: {
  imports = [../../modules/mule.nix];

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
        "arc"
        "discord"
        "firefox"
        "firefox@developer-edition"
        #"hammerspoon"
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
        "transmission"
      ]);
  };

  mule = {
    enable = isCorpManaged;
    packages = [
      "Android Studio with Blaze Canary"
      "srcfs"
    ];
  };

  # The user should already exist, but we need to set this up so Nix knows
  # what our home directory is (https://github.com/LnL7/nix-darwin/issues/423).
  users.users.delay = {
    home = "/Users/delay";
    shell = pkgs.fish;
  };
}
