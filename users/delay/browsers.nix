{
  lib,
  pkgs,
  ...
} @ args: let
  inherit ((lib.user.getUserConfig args).modules.usrenv) isCorpManaged isLinuxDesktop;
in
  lib.mkIf isLinuxDesktop {
    programs = {
      chromium = {
        enable = !isCorpManaged;
        package = pkgs.google-chrome;
        commandLineArgs = [
          # Enable to automatically spoof the user agent to something the JP tax site accepts.
          # "--user-agent='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.2 Safari/605.1.15'"
          "--enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoEncoder,Vulkan,VulkanFromANGLE,DefaultANGLEVulkan,VaapiIgnoreDriverChecks,VaapiVideoDecoder,PlatformHEVCDecoderSupport,UseMultiPlaneFormatForHardwareVideo"
        ];
        dictionaries = with pkgs; [
          hunspellDictsChromium.en_US
          hunspellDictsChromium.fr_FR
        ];
        extensions = [
          {id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa";} # 1Password
          {id = "nngceckbapebfimnlniiiahkandclblb";} # Bitwarden
          {id = "cjpalhdlnbpafiamejdnhcphjbkeiagm";} # uBlock Origin
        ];
      };

      firefox = {
        enable = true;
        package = pkgs.firefox;
        languagePacks = ["en_US" "fr_FR" "ja_JP"];
        profiles = import ./firefox/profiles.nix {
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
          };
        };
      };
    };

    xdg.mimeApps = lib.mkIf (!isCorpManaged) {
      defaultApplications = let
        browserList = ["firefox.desktop" "google-chrome.desktop"];
      in {
        "default-web-browser" = browserList;
        "text/html" = browserList;
        "text/xml" = browserList;
        "application/xhtml+xml" = browserList;
        "application/xhtml_xml" = browserList;
        "application/xml" = browserList;
        "x-scheme-handler/http" = browserList;
        "x-scheme-handler/https" = browserList;
        "x-scheme-handler/about" = browserList;
        "x-scheme-handler/unknown" = browserList;
      };
    };
  }
