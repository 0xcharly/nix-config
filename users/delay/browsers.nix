{pkgs, ...} @ args: let
  config =
    if args ? osConfig
    then args.osConfig
    else args.config;

  enable = pkgs.stdenv.isLinux && !config.modules.usrenv.isHeadless;
in {
  # Only used when full-page translation is needed, or if the target website
  # _really_ wants an actual Google Chrome browser.
  home.packages = let
    google-chrome-for-jp-taxes = pkgs.google-chrome.override {
      commandLineArgs = [
        "--enable-features=VaapiVideoDecoder,VaapiIgnoreDriverChecks,DefaultANGLEVulkan,VulkanFromANGLE"
        "--gpu-testing-vendor-id=0x1002"
        "--gpu-testing-device-id=0x747e"
        "--user-agent='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.2 Safari/605.1.15'"
      ];
    };
  in [google-chrome-for-jp-taxes];

  programs.chromium = {
    inherit enable;
    package = pkgs.ungoogled-chromium;
    dictionaries = with pkgs; [
      hunspellDictsChromium.en_US
      hunspellDictsChromium.fr_FR
    ];
    extensions = [
      {id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa";} # 1Password
      {id = "cdglnehniifkbagbbombnjghhcihifij";} # Kagi Search
      {id = "cjpalhdlnbpafiamejdnhcphjbkeiagm";} # uBlock Origin
    ];
  };

  programs.firefox = {
    inherit enable;
    package = pkgs.firefox;
    languagePacks = ["en_US" "fr_FR"];

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
    profiles.default = {
      id = 0;
      isDefault = true;
      name = "Default";
      containers = {
        primary = {
          color = "blue";
          icon = "fingerprint";
          id = 1;
        };
        alt = {
          color = "yellow";
          icon = "fingerprint";
          id = 2;
        };
        dev = {
          color = "toolbar";
          icon = "fingerprint";
          id = 3;
        };
        shopping = {
          color = "pink";
          icon = "cart";
          id = 4;
        };
        banking = {
          color = "green";
          icon = "dollar";
          id = 5;
        };
        spam = {
          color = "orange";
          icon = "fence";
          id = 6;
        };
        media = {
          color = "purple";
          icon = "cart";
          id = 7;
        };
        dangerous = {
          color = "red";
          icon = "fingerprint";
          id = 8;
        };
      };
      containersForce = true;
      # See: https://github.com/nix-community/nur-combined/blob/master/repos/rycee/pkgs/firefox-addons/generated-firefox-addons.nix
      extensions = with pkgs.nur.repos.rycee.firefox-addons; [
        consent-o-matic
        cookie-autodelete
        facebook-container
        multi-account-containers
        # NOTE: The 1Password database is regularly corrupted on restart.
        # The assumption is that the add-on is auto-updated when firefox is
        # running and then overwrote by subsequent `nixos-rebuild switch`.
        # Add-ons auto-update was disabled for this reason. This may cause other
        # issues in the future where the browser extension version gets out of
        # sync with the desktop client.
        # The alternative would be to manually install this extension.
        onepassword-password-manager
        privacy-badger
        proton-pass
        simple-translate
        ublock-origin
      ];

      search = {
        default = "Kagi Search";
        # Workaround to Firefox replacing `search.json.mozlz4` symlink.
        # https://github.com/nix-community/home-manager/issues/3698
        force = true;
        engines = {
          "Kagi Search" = {
            urls = [
              {template = "https://kagi.com/search?q={searchTerms}";}
              {
                template = "https://kagi.com/api/autosuggest?q={searchTerms}";
                type = "application/x-suggestions+json";
              }
            ];
            iconUpdateURL = "https://github.com/kagisearch/browser_extensions/blob/e65c723370a2ee3960120612d2d46f3c9bfb6d87/shared/icons/icon_32px.png?raw=true";
            updateInterval = 7 * 24 * 60 * 60 * 1000; # Weekly
            definedAliases = ["k"];
          };

          "Nix Packages" = {
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "type";
                    value = "packages";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];

            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = ["@np"];
          };

          "Home Manager Options" = {
            urls = [{template = "https://home-manager-options.extranix.com/?query={searchTerms}";}];
            iconUpdateURL = "https://home-manager-options.extranix.com/images/favicon.png";
            updateInterval = 7 * 24 * 60 * 60 * 1000; # Weekly
            definedAliases = ["@hm"];
          };

          "NixOS Wiki" = {
            urls = [{template = "https://wiki.nixos.org/w/index.php?search={searchTerms}";}];
            iconUpdateURL = "https://wiki.nixos.org/favicon.png";
            updateInterval = 24 * 60 * 60 * 1000; # Daily
            definedAliases = ["@nw"];
          };

          "GitHub Code Search" = {
            urls = [{template = "https://github.com/search?q={searchTerms}&type=code";}];
            iconUpdateURL = "https://github.com/fluidicon.png";
            updateInterval = 7 * 24 * 60 * 60 * 1000; # Weekly
            definedAliases = ["cs"];
          };

          # Hide the rest, we don't need it.
          "Google".metaData.hidden = true;
          "Amazon.com".metaData.hidden = true;
          "Amazon.co.uk".metaData.hidden = true;
          "Bing".metaData.hidden = true;
          "eBay".metaData.hidden = true;
          "DuckDuckGo".metaData.hidden = true;
        };
      };

      settings = {
        "extensions.autoDisableScopes" = 0;
      };

      # A somewhat more compact UI.
      userChrome = builtins.readFile ./userChrome.css;
    };
  };

  xdg.mimeApps = {
    defaultApplications = {
      "x-scheme-handler/http" = ["firefox.desktop" "chromium.desktop"];
      "x-scheme-handler/https" = ["firefox.desktop" "chromium.desktop"];
      "text/html" = ["firefox.desktop"];
      "x-scheme-handler/about" = ["firefox.desktop"];
      "x-scheme-handler/unknown" = ["firefox.desktop"];
    };
  };
}
