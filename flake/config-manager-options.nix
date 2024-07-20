{
  config,
  lib,
}: let
  inherit (lib) mkOption mkOptionType types;
  cfg = config.config-manager;

  requireConfigRoot = lib.throwIfNot (cfg ? root) "config-manager.root must be set" cfg.root;

  userOptionsSubmodule.options = {
    system = mkOption {
      default = cfg.home.defaultSystem;
      type = types.str;
      description = ''
        The default system to use for this user configuration.
      '';
    };

    user = mkOption {
      default = cfg.defaultUser;
      type = types.nullOr types.str;
      description = ''
        The name of the owning user.
      '';
    };
  };

  mkModulesDirectoriesOptions = prefix: let
    supportedPrefixes = [
      "home"
      "darwin"
      "nixos"
    ];
    throwForUnsupportedPrefix = expr:
      lib.throwIfNot (builtins.elem prefix supportedPrefixes) "Internal error: unsupported prefix '${prefix}'" expr;
  in
    throwForUnsupportedPrefix {
      configModulesDirectory = mkOption {
        default = "${requireConfigRoot}/hosts/${prefix}-configs";
        defaultText = lib.literalExpression "\"\${config-manager.root}/hosts/${prefix}-configs\"";
        type = types.pathInStore;
        description = ''
          The directory containing configuration modules for ${prefix}.
        '';
      };

      sharedModulesDirectory = mkOption {
        default = "${requireConfigRoot}/hosts/${prefix}-modules";
        defaultText = lib.literalExpression "\"\${config-manager.root}/hosts/${prefix}-modules\"";
        type = types.pathInStore;
        description = ''
          The directory containing shared modules for ${prefix}.
        '';
      };
    };

  hostOptionsSubmodule.options = {
    user = mkOption {
      default = cfg.defaultUser;
      type = types.nullOr types.str;
      description = ''
        The name of the owning user.
      '';
    };
  };

  mkSystemConfigurationOptions = system: let
    supportedSystems = ["darwin" "nixos"];
    throwForUnsupportedSystems = expr:
      lib.throwIfNot (builtins.elem system supportedSystems) "Internal error: unsupported system '${system}'" expr;
  in
    throwForUnsupportedSystems {
      hosts = mkOption {
        default = {};
        type = types.attrsOf (types.submodule hostOptionsSubmodule);
        example = lib.literalExpression ''
          {
            hostname = {
              user = "bob";
            };
          }
        '';
        description = ''
          Settings for creating ${system}Configurations.

          It's not neccessary to specify this option to create flake outputs.
          It's only needed if you want to change the defaults for specific ${system}Configurations.
        '';
      };
    };

  nixosConfigurationOptions =
    mkModulesDirectoriesOptions "nixos"
    // mkSystemConfigurationOptions "nixos";

  darwinConfigurationOptions =
    mkModulesDirectoriesOptions "darwin"
    // mkSystemConfigurationOptions "darwin";

  homeConfigurationOptions =
    mkModulesDirectoriesOptions "home"
    // {
      defaultSystem = mkOption {
        default = "x86_64-linux";
        type = types.str;
        description = ''
          The default system to use for standalone user configurations.
        '';
      };

      users = mkOption {
        default = {};
        type = types.attrsOf (types.submodule userOptionsSubmodule);
        example = lib.literalExpression ''
          {
            alice = {
              system = "x86_64-linux";
            };
          }
        '';
        description = ''
          Settings for creating homeConfigurations.

          It's not neccessary to specify this option to create flake outputs.
          It's only needed if you want to change the defaults for specific homeConfigurations.
        '';
      };
    };

  overlayType = mkOptionType {
    name = "nixpkgs-overlay";
    description = "nixpkgs overlay";
    check = lib.isFunction;
    merge = lib.mergeOneOption;
  };

  mkDefaultOptions = options: let
    requireDefault = name: value: lib.throwIfNot (value ? default) "Internal error: missing default value for option '${name}" value.default;
  in
    lib.mapAttrs (name: value: requireDefault name value) options;
in {
  config-manager = {
    root = mkOption {
      type = types.pathInStore;
      example = lib.literalExpression "./.";
      description = ''
        The root from which configurations and modules should be searched.
      '';
    };

    overlays = mkOption {
      default = [];
      type = types.listOf overlayType;
      description = ''
        A list of nixpkgs overlays to apply to all configurations.
        This option allows modifying the Nixpkgs package set accessed through the `pkgs` module argument.
      '';
    };

    defaultUser = mkOption {
      default = null;
      type = types.nullOr types.str;
      description = ''
        Default user to install for all systems.
      '';
    };

    backupFileExtension = mkOption {
      type = types.nullOr types.str;
      default = "nix-backup";
      example = "nix-backup";
      description = ''
        On activation move existing files by appending the given file
        extension rather than exiting with an error.
      '';
    };

    globalModulesDirectory = mkOption {
      default = "${requireConfigRoot}/globals";
      defaultText = lib.literalExpression "\"\${config-manager.root}/globals\"";
      type = types.pathInStore;
      description = ''
        The directory containing modules shared with all configurations.
      '';
    };

    usersModulesDirectory = mkOption {
      default = "${requireConfigRoot}/users";
      defaultText = lib.literalExpression "\"\${config-manager.root}/users\"";
      type = types.pathInStore;
      description = ''
        The directory containing user configuration modules shared with all systems.
      '';
    };

    home = homeConfigurationOptions;
    nixos = nixosConfigurationOptions;
    darwin = darwinConfigurationOptions;
  };

  defaults = {
    hostSettings = mkDefaultOptions hostOptionsSubmodule.options;
    userSettings = mkDefaultOptions userOptionsSubmodule.options;
  };
}
