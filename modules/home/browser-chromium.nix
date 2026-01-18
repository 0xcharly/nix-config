# Use the following cmdline to automatically spoof the user agent to something the JP tax site accepts.
#   --user-agent='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.2 Safari/605.1.15'
{
  lib,
  pkgs,
  ...
}:
{
  programs.chromium = {
    enable = true;
    package = lib.mkDefault pkgs.ungoogled-chromium;
    dictionaries = with pkgs.hunspellDictsChromium; [
      en_US
      fr_FR
    ];
    extensions = [
      { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
    ];
  };
}
