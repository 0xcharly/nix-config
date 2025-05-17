{
  lib,
  pkgs,
  ...
} @ args: let
  config =
    if args ? osConfig
    then args.osConfig
    else args.config;
  inherit (config.modules.usrenv) isCorpManaged isLinuxDesktop;

  firefox-language-packs = ["en_US" "fr_FR" "ja_JP"];
  firefox-profiles = import ./firefox/profiles.nix {
    firefox-addons = pkgs.nur.repos.rycee.firefox-addons;
    nixos-icons = pkgs.nixos-icons;
  };
in
  lib.mkIf isLinuxDesktop {
    # Only used when full-page translation is needed, or if the target website
    # _really_ wants an actual Google Chrome browser.
    home.packages = let
      google-chrome-for-jp-taxes = pkgs.google-chrome.override {
        commandLineArgs = [
          "--enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoEncoder,Vulkan,VulkanFromANGLE,DefaultANGLEVulkan,VaapiIgnoreDriverChecks,VaapiVideoDecoder,PlatformHEVCDecoderSupport,UseMultiPlaneFormatForHardwareVideo"
          "--user-agent='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.2 Safari/605.1.15'"
        ];
      };
    in
      lib.mkIf (!isCorpManaged) [google-chrome-for-jp-taxes];

    programs.chromium = {
      enable = !isCorpManaged;
      package = pkgs.ungoogled-chromium;
      dictionaries = with pkgs; [
        hunspellDictsChromium.en_US
        hunspellDictsChromium.fr_FR
      ];
      extensions = [
        {id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa";} # 1Password
        {id = "cdglnehniifkbagbbombnjghhcihifij";} # Kagi Search
        {id = "ghmbeldphafepmbegfdlkpapadhbakde";} # Proton Pass
        {id = "cjpalhdlnbpafiamejdnhcphjbkeiagm";} # uBlock Origin
      ];
    };

    programs.librewolf = {
      enable = true;
      languagePacks = firefox-language-packs;

      settings = {
        # https://librewolf.net/docs/faq/#what-are-the-most-common-downsides-of-rfp-resist-fingerprinting
        "privacy.resistFingerprinting" = false;
        "privacy.fingerprintingProtection" = true;
        "privacy.fingerprintingProtection.overrides" = "+AllTargets,-CSSPrefersColorScheme";
      };

      profiles = firefox-profiles;

      # Check about:policies#documentation for options.
      # Required for userChrome.
      policies.Preferences."toolkit.legacyUserProfileCustomizations.stylesheets" = {
        Value = true;
        Status = "locked";
      };
    };

    programs.firefox = {
      enable = true;
      package = pkgs.firefox;
      languagePacks = firefox-language-packs;
      profiles = firefox-profiles;

      # Check about:policies#documentation for options.
      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
        };
        DisablePocket = true;
        DisableFirefoxAccounts = true;
        DisableAccounts = true;
        DisableFirefoxScreenshots = true;
        OverrideFirstRunPage = "";
        OverridePostUpdatePage = "";
        DontCheckDefaultBrowser = true;
        DisplayBookmarksToolbar = "never"; # alternatives: "always" or "newtab"
        DisplayMenuBar = "default-off"; # alternatives: "always", "never" or "default-on"
        SearchBar = "unified"; # alternative: "separate"

        # Check about:config for options.
        Preferences = let
          lock = value: {
            Value = value;
            Status = "locked";
          };
        in {
          "gfx.webrender.all" = lock true; # Hardware acceleration.
          "browser.contentblocking.category" = lock "strict";
          "browser.formfill.enable" = lock false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = lock false;
          "browser.newtabpage.activity-stream.feeds.snippets" = lock false;
          "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = lock false;
          "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = lock false;
          "browser.newtabpage.activity-stream.section.highlights.includePocket" = lock false;
          "browser.newtabpage.activity-stream.section.highlights.includeVisited" = lock false;
          "browser.newtabpage.activity-stream.showSponsored" = lock false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock false;
          "browser.newtabpage.activity-stream.system.showSponsored" = lock false;
          "browser.search.suggest.enabled" = lock false;
          "browser.search.suggest.enabled.private" = lock false;
          "browser.startup.page" = lock 3;
          "browser.topsites.contile.enabled" = lock false;
          "browser.urlbar.showSearchSuggestionsFirst" = lock false;
          "browser.urlbar.suggest.searches" = lock false;
          "extensions.pocket.enabled" = lock false;
          "extensions.screenshots.disabled" = lock true;
          "extensions.update.enabled" = lock false;
          "toolkit.legacyUserProfileCustomizations.stylesheets" = lock true; # Required for userChrome.
        };
      };
    };

    xdg.mimeApps = {
      defaultApplications = lib.mkIf (!isCorpManaged) {
        "default-web-browser" = ["chromium.desktop"];
        "text/html" = ["chromium.desktop"];
        "text/xml" = ["chromium.desktop"];
        "application/xhtml+xml" = ["chromium.desktop"];
        "application/xhtml_xml" = ["chromium.desktop"];
        "application/xml" = ["chromium.desktop"];
        "x-scheme-handler/http" = ["chromium.desktop" "firefox.desktop"];
        "x-scheme-handler/https" = ["chromium.desktop" "firefox.desktop"];
        "x-scheme-handler/about" = ["chromium.desktop"];
        "x-scheme-handler/unknown" = ["chromium.desktop"];
      };
    };
  }
