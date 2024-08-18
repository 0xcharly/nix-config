{
  config,
  lib,
  ...
}: let
  inherit (builtins) elemAt;
  inherit (lib.lists) optionals;
  inherit (lib.modules) mkMerge;
  inherit (lib.options) mkOption;
  inherit (lib.types) enum listOf str;

  cfg = config.modules.system;
in {
  options.modules.system = {
    mainUser = mkOption {
      type = enum cfg.users;
      default = elemAt cfg.users 0;
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
  };

  config.warnings = mkMerge [
    (optionals (config.modules.system.users == []) [
      ''
        You have not added any users to be supported by your system. You may end up with an unbootable system!

        Consider setting {option}`config.modules.system.users` in your configuration
      ''
    ])
  ];
}
