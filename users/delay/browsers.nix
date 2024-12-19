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
    package = pkgs.firefox-devedition;
  };
}
