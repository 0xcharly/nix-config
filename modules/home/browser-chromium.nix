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
