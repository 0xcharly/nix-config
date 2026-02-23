# Use the following cmdline to automatically spoof the user agent to something the JP tax site accepts.
#   --user-agent='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.2 Safari/605.1.15'
{
  lib,
  pkgs,
  ...
}:
let
  # Masquerade Google Chrome as Safari to bypass the e-tax website OS/browser check.
  google-chrome-as-safari = pkgs.google-chrome.override {
    commandLineArgs = lib.concatStringsSep " " [
      "--user-agent='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.2 Safari/605.1.15'"
      "--disable-features=UserAgentClientHint"
    ];
  };
in
{
  home.packages = [ google-chrome-as-safari ];
}
