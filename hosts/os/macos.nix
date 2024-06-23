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
        "protonvpn"
        "transmission"
      ]);
  };

  mule = {
    enable = isCorpManaged;
    packages = [
      "android-studio-with-blaze-canary"
      "srcfs"
    ];
  };

  # Enable the `sudo` touch ID prompt.
  security.pam.enableSudoTouchIdAuth = true;

  # Unbork the dock.
  system.defaults.dock = {
    autohide = true;
    autohide-delay = 0.0;
    autohide-time-modifier = 0.4;
    expose-animation-duration = 0.4;
    orientation = "left";
    persistent-apps = [];
    persistent-others = [];
    show-process-indicators = false;
    show-recents = false;
    static-only = true;

    tilesize = 32;
    magnification = true;
    largesize = 48;

    # Disable hot corners.
    wvous-tl-corner = 1;
    wvous-bl-corner = 1;
    wvous-tr-corner = 1;
    wvous-br-corner = 1;

    mru-spaces = false;
  };

  system.defaults.loginwindow.GuestEnabled = false;

  system.defaults.NSGlobalDomain = {
    AppleShowAllFiles = true;
    AppleInterfaceStyle = "Dark";
    AppleShowAllExtensions = true;
    NSAutomaticCapitalizationEnabled = false;
    NSAutomaticDashSubstitutionEnabled = false;
    NSAutomaticPeriodSubstitutionEnabled = false;
    NSAutomaticQuoteSubstitutionEnabled = false;
    NSAutomaticSpellingCorrectionEnabled = false;

    InitialKeyRepeat = 10;
    KeyRepeat = 1;

    "com.apple.sound.beep.volume" = 0.0;
  };

  system.defaults.finder = {
    AppleShowAllFiles = true;
    FXPreferredViewStyle = "clmv";
    FXEnableExtensionChangeWarning = false;
  };

  system.defaults.trackpad.ActuationStrength = 0; # Silent clicking.
  system.defaults.universalaccess.mouseDriverCursorSize = 1.5; # Larger cursor.

  # The user should already exist, but we need to set this up so Nix knows
  # what our home directory is (https://github.com/LnL7/nix-darwin/issues/423).
  users.users.delay = {
    home = "/Users/delay";
    shell = pkgs.fish;
  };
}
