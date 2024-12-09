{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib.attrsets) genAttrs;
  inherit (lib.lists) optionals;
  inherit (lib.modules) mkMerge;
  inherit (lib.options) mkOption;
  inherit (lib.types) attrsOf enum int listOf str;
  inherit (pkgs.stdenv) isDarwin;

  cfg = config.modules.system;
in {
  options.modules.system = {
    mainUser = mkOption {
      type = enum (builtins.attrNames cfg.users);
      default = "delay";
      description = ''
        The username of the main user for your system.

        In case of a multiple systems, this will be the user with priority in ordered lists and enabled options.
      '';
    };

    users = mkOption {
      # TODO: better typing.
      type = attrsOf (attrsOf str);
      default = let
        mkUser = ldap: {
          name = ldap;
          home =
            if isDarwin
            then "/Users/${ldap}"
            else "/home/${ldap}";
        };
      in
        genAttrs ["delay"] mkUser;
      description = "A list of home-manager users on the system.";
    };

    hosts = {
      asl = {
        networking = {
          address = mkOption {
            type = str;
            default = "192.168.70.3";
            description = "The local IPv4 address of the ASL virtual machine";
          };
          prefixLength = mkOption {
            type = int;
            default = 24;
            description = ''
              Subnet mask of the IPv4 address, specified as the number of
              bits in the prefix.
            '';
          };
          defaultGateway = mkOption {
            type = str;
            default = "192.168.70.2";
            description = "The IPv4 address of the gateway used by the ASL virtual machine";
          };
          nameservers = mkOption {
            type = listOf str;
            default = ["192.168.70.2"];
            description = "The list of nameservers used by the ASL virtual machine";
          };
        };
      };
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
