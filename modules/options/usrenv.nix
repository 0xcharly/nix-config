{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (builtins) elemAt;
  inherit (lib.lists) optionals;
  inherit (lib.modules) mkMerge;
  inherit (lib.options) mkOption;
  inherit (lib.types) bool enum listOf str;
  inherit (pkgs.stdenv) isDarwin;

  cfg = config.usrenv;
in {
  options.usrenv = mkOption {
    mainUser = mkOption {
      type = enum config.modules.system.users;
      default = elemAt config.modules.system.users 0;
      description = ''
        The username of the main user for your system.

        In case of a multiple systems, this will be the user with priority in ordered lists and enabled options.
      '';
    };

    users = mkOption {
      type = listOf str;
      default = ["delay"];
      description = "A list of home-manager users on the system.";
    };

    options.isCorpManaged = mkOption {
      default = false;
      type = bool;
      description = ''
        Whether this host is managed by my employer.
      '';
    };

    options.compositor = mkOption {
      default = "headless";
      type = enum ["headless" "quartz" "x11" "wayland"];
      description = ''
        Which compositor to use for the graphical environment on Linux.

        Use `headless` for a system without a graphical environment.
        macOS only supports `quartz`.
      '';
    };
  };

  config.assertions = [
    {
      assertion = isDarwin -> cfg.compositor == "quartz";
      message = "macOS only supports the `quartz` compositor.";
    }
  ];

  config.warnings = mkMerge [
    (optionals (config.modules.system.users == []) [
      ''
        You have not added any users to be supported by your system. You may end up with an unbootable system!

        Consider setting {option}`config.modules.system.users` in your configuration
      ''
    ])
  ];
}
