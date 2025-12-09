{
  lib,
  firefox-addons,
  nixos-icons,
}: let
  alternate-player-for-twitch-dot-tv = firefox-addons.buildFirefoxXpiAddon rec {
    pname = "alternate-player-for-twitch-dot-tv";
    version = "2025.6.16";
    addonId = "twitch5@coolcmd";
    url = "https://addons.mozilla.org/firefox/downloads/file/4514838/twitch_5-${version}.xpi";
    sha256 = "sha256-ShV3BybtKD5P3Nvt5wVDONnO1Go6YxBI48VO4yw+IQw=";
    meta = with lib; {
      homepage = "https://addons.mozilla.org/en-US/firefox/addon/twitch_5/";
      description = "Alternate player of live broadcasts for Twitch.tv website.";
      license = licenses.bsd3;
      mozPermissions = [
        "*://m.twitch.tv/*"
        "*://www.twitch.tv/*"
        "*://twitch.tv/*"
        "*://twitchcdn.net/*"
        "*://ttvnw.net/*"
        "*://jtvnw.net/*"
        "*://live-video.net/*"
        "*://akamaized.net/*"
        "*://cloudfront.net/*"
        "clipboardWrite"
      ];
      platforms = platforms.all;
    };
  };
in {
  default = {
    id = 0;
    isDefault = true;
    name = "Default";
    # See: https://github.com/nix-community/nur-combined/blob/master/repos/rycee/pkgs/firefox-addons/generated-firefox-addons.nix
    extensions.packages = with firefox-addons; [
      alternate-player-for-twitch-dot-tv
      bitwarden
      clearurls
      simple-translate
      ublock-origin
    ];

    search = {
      default = "google";
      # Workaround to Firefox replacing `search.json.mozlz4` symlink.
      # https://github.com/nix-community/home-manager/issues/3698
      force = true;
      engines = {
        "Nix Packages" = {
          urls = [{template = "https://search.nixos.org/packages?query={searchTerms}";}];
          icon = "${nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          updateInterval = 7 * 24 * 60 * 60 * 1000; # Weekly
          definedAliases = ["@np"];
        };

        "Nix Options" = {
          urls = [{template = "https://search.nixos.org/options?query={searchTerms}";}];
          icon = "${nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          updateInterval = 7 * 24 * 60 * 60 * 1000; # Weekly
          definedAliases = ["@no"];
        };

        "Home Manager Options" = {
          urls = [{template = "https://home-manager-options.extranix.com/?query={searchTerms}";}];
          icon = "https://home-manager-options.extranix.com/images/favicon.png";
          updateInterval = 7 * 24 * 60 * 60 * 1000; # Weekly
          definedAliases = ["@hm"];
        };

        "NixOS Wiki" = {
          urls = [{template = "https://wiki.nixos.org/w/index.php?search={searchTerms}";}];
          icon = "https://wiki.nixos.org/favicon.png";
          updateInterval = 24 * 60 * 60 * 1000; # Daily
          definedAliases = ["@nw"];
        };

        "GitHub Code Search" = {
          urls = [{template = "https://github.com/search?type=code&q={searchTerms}";}];
          icon = "https://github.com/fluidicon.png";
          updateInterval = 7 * 24 * 60 * 60 * 1000; # Weekly
          definedAliases = ["cs"];
        };

        # Hide the rest, we don't need it.
        "amazondotcom-us".metaData.hidden = true;
        "bing".metaData.hidden = true;
        "ebay".metaData.hidden = true;
        "ddg".metaData.hidden = true;
      };
    };

    settings = {
      "extensions.autoDisableScopes" = 0;
    };
  };
}
