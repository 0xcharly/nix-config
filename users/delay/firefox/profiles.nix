{
  firefox-addons,
  nixos-icons,
}: {
  default = {
    id = 0;
    isDefault = true;
    name = "Default";
    containers = {
      Primary = {
        color = "blue";
        icon = "fingerprint";
        id = 1;
      };
      Secondary = {
        color = "yellow";
        icon = "fingerprint";
        id = 2;
      };
      Spam = {
        color = "orange";
        icon = "fence";
        id = 3;
      };
      Dev = {
        color = "toolbar";
        icon = "fingerprint";
        id = 4;
      };
      Entertainment = {
        color = "purple";
        icon = "chill";
        id = 5;
      };
      Shopping = {
        color = "pink";
        icon = "cart";
        id = 6;
      };
      Banking = {
        color = "green";
        icon = "dollar";
        id = 7;
      };
      Dangerous = {
        color = "red";
        icon = "fingerprint";
        id = 8;
      };
    };
    containersForce = true;
    # See: https://github.com/nix-community/nur-combined/blob/master/repos/rycee/pkgs/firefox-addons/generated-firefox-addons.nix
    extensions = with firefox-addons; [
      clearurls
      consent-o-matic
      cookie-autodelete
      facebook-container
      multi-account-containers
      nighttab
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

          icon = "${nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
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
  };
}
