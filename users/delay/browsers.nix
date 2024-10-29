{pkgs, ...} @ args: let
  config =
    if args ? osConfig
    then args.osConfig
    else args.config;
in {
  programs.chromium = {
    enable = pkgs.stdenv.isLinux && !config.modules.usrenv.isHeadless;
    extensions = [
      {id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa";} # 1Password
      {id = "cjpalhdlnbpafiamejdnhcphjbkeiagm";} # uBlock Origin
    ];
  };
}
