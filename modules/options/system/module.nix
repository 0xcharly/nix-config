{
  config,
  lib,
  ...
}: let
  inherit (builtins) elemAt;
  inherit (lib.lists) optionals;
  inherit (lib.modules) mkMerge;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) enum listOf str package;
in {
  imports = [
    # configuration options for system activation scripts
    ./activation.nix
  ];
  config = {
    warnings = mkMerge [
      (optionals (config.modules.system.users == []) [
        ''
          You have not added any users to be supported by your system. You may end up with an unbootable system!

          Consider setting {option}`config.modules.system.users` in your configuration
        ''
      ])
    ];
  };

  options.modules.system = {
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

    "3dprint" = {
      enable = mkEnableOption "3D printing suite";
      extraPrograms = mkOption {
        type = listOf package;
        default = [];
        description = "A list of extra programs to enable for 3D printing";
      };
    };
  };
}
