{pkgs, ...} @ args: let
  config =
    if args ? osConfig
    then args.osConfig
    else args.config;

  enable = pkgs.stdenv.isLinux && !config.modules.usrenv.isHeadless;
in {
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
        lock-false = {
          Value = false;
          Status = "locked";
        };
        lock-true = {
          Value = true;
          Status = "locked";
        };
      in {
        "browser.contentblocking.category" = {
          Value = "strict";
          Status = "locked";
        };
        "extensions.pocket.enabled" = lock-false;
        "extensions.screenshots.disabled" = lock-true;
        "browser.topsites.contile.enabled" = lock-false;
        "browser.formfill.enable" = lock-false;
        "browser.search.suggest.enabled" = lock-false;
        "browser.search.suggest.enabled.private" = lock-false;
        "browser.urlbar.suggest.searches" = lock-false;
        "browser.urlbar.showSearchSuggestionsFirst" = lock-false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = lock-false;
        "browser.newtabpage.activity-stream.feeds.snippets" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includePocket" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includeVisited" = lock-false;
        "browser.newtabpage.activity-stream.showSponsored" = lock-false;
        "browser.newtabpage.activity-stream.system.showSponsored" = lock-false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock-false;
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
        onepassword-password-manager
        privacy-badger
        simple-translate
        ublock-origin
      ];

      search = {
        default = "Kagi Search";
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

          "NixOS Wiki" = {
            urls = [{template = "https://wiki.nixos.org/index.php?search={searchTerms}";}];
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
        };
      };

      settings = {
        "extensions.autoDisableScopes" = 0;
      };
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
