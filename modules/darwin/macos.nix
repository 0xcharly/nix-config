{
  # Enable the `sudo` touch ID prompt.
  security.pam.enableSudoTouchIdAuth = true;

  # Unbork the dock.
  system.defaults.dock = {
    autohide = true;
    autohide-delay = 0.0;
    autohide-time-modifier = 0.4;
    expose-animation-duration = 0.1;
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

  # To re-enable, either set if to `true` (i.e. removing this line will *not*
  # revert to the default setting) or run `sudo nvram StartupMute=%00`.
  system.startup.chime = false;
}