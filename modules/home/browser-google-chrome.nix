{
  lib,
  pkgs,
  ...
}:
{
  programs.chromium = {
    enable = true;
    package = lib.mkDefault pkgs.google-chrome;
    dictionaries = with pkgs.hunspellDictsChromium; [
      en_US
      fr_FR
    ];
    extensions = [
      { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # uBlock Origin
    ];
  };
}
