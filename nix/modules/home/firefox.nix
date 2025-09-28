{pkgs, ...}: {
  programs.firefox = {
    enable = true;
    package = pkgs.firefox;
    languagePacks = ["en_US" "fr_FR" "ja_JP"];
    profiles = import ./firefox-profiles.nix {
      inherit (pkgs) nixos-icons;
      inherit (pkgs.nur.repos.rycee) firefox-addons;
    };

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
      OfferToSaveLogins = false;
      OfferToSaveLoginsDefault = false;
      PasswordManagerEnabled = false;
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
        "services.sync.engine.passwords" = lock false;
        "signon.rememberSignons" = lock false;
      };
    };
  };
}
