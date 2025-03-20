{
  pkgs,
  lib,
  ...
} @ args: let
  config =
    if args ? osConfig
    then args.osConfig
    else args.config;
  inherit (pkgs.stdenv) isLinux;
  inherit (config.modules.usrenv) isHeadless;

  isLinuxDesktop = isLinux && !isHeadless;
in
  lib.mkIf isLinuxDesktop {
    services.flameshot = {
      enable = true;
      package = pkgs.flameshot.override {enableWlrSupport = true;};
      settings = {
        General = {
          disabledTrayIcon = true;
          showStartupLaunchMessage = false;
        };
      };
    };
  }
