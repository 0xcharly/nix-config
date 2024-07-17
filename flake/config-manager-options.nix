{
  config,
  lib,
}: let
  inherit (lib) mkOption mkOptionType types;
  cfg = config.config-manager;

  requireConfigRoot = lib.throwIfNot (cfg ? root) "config-manager.root must be set" cfg.root;

  userOptionsSubmodule.options = {
    injectArgs = mkOption {
      default = {};
      type = types.attrsOf types.anything;
      description = ''
        Extra arguments to pass to this host's home configuration.
      '';
    };

    system = mkOption {
      default = cfg.home.defaultSystem;
      type = types.str;
      description = ''
        The default system to use for this user configuration.
      '';
    };
  };

  mkModulesDirectoriesOptions = prefix: let
    supportedPrefixes = [
      "home"
      "macos"
      "nixos"
    ];
    throwForUnsupportedPrefix = expr:
      lib.throwIfNot (builtins.elem prefix supportedPrefixes) "Internal error: unsupported prefix '${prefix}'" expr;
  in
    throwForUnsupportedPrefix {
      sharedModulesDirectory = mkOption {
        default = "${requireConfigRoot}/${prefix}-shared-modules";
        defaultText = lib.literalExpression "\"\${config-manager.root}/${prefix}-shared-modules\"";
        type = types.pathInStore;
        description = ''
          The directory containing shared modules for ${prefix}.
        '';
      };

      configModulesDirectory = mkOption {
        default = "${requireConfigRoot}/${prefix}-config-modules";
        defaultText = lib.literalExpression "\"\${config-manager.root}/${prefix}-config-modules\"";
        type = types.pathInStore;
        description = ''
          The directory containing configuration modules for ${prefix}.
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

    injectArgs = mkOption {
      default = {};
      type = types.attrsOf types.anything;
      description = ''
        Extra arguments to pass to this host's system and home configuration.
      '';
    };

    osInjectArgs = mkOption {
      default = {};
      type = types.attrsOf types.anything;
      description = ''
        Extra arguments to pass to this host's system configuration.
      '';
    };

    hmInjectArgs = mkOption {
      default = {};
      type = types.attrsOf types.anything;
      description = ''
        Extra arguments to pass to this host's home configuration.
      '';
    };

    # TODO: consider a global option for this.
    hmBackupFileExtension = mkOption {
      type = types.nullOr types.str;
      default = "nix-backup";
      example = "nix-backup";
      description = ''
        On activation move existing files by appending the given file
        extension rather than exiting with an error.
      '';
    };
  };

  mkSystemConfigurationOptions = system: let
    supportedSystems = ["macos" "nixos"];
    throwForUnsupportedSystems = expr:
      lib.throwIfNot (builtins.elem system supportedSystems) "Internal error: unsupported system '${system}'" expr;
  in
    throwForUnsupportedSystems {
      injectArgs = mkOption {
        default = {};
        type = types.attrsOf types.anything;
        description = ''
          Extra arguments to pass to all ${system}Configurations.
        '';
      };

      hosts = mkOption {
        default = {};
        type = types.attrsOf (types.submodule hostOptionsSubmodule);
        example = lib.literalExpression ''
          {
            hostA = {
              userHomeModules = [ "bob" ];
            };

            hostB = {
              arch = "aarch64
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

  macosConfigurationOptions =
    mkModulesDirectoriesOptions "macos"
    // mkSystemConfigurationOptions "macos";

  homeConfigurationOptions =
    mkModulesDirectoriesOptions "home"
    // {
      injectArgs = mkOption {
        default = {};
        type = types.attrsOf types.anything;
        description = ''
          Extra arguments to pass to all homeConfigurations.
        '';
      };

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
              standalone = {
                enable = true;
                pkgs = import nixpkgs { system = "x86_64-linux"; };
              };
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

    injectArgs = mkOption {
      default = {};
      example = lib.literalExpression "{ inherit inputs; }";
      type = types.attrsOf types.anything;
      description = ''
        Extra arguments to pass to all configurations.
      '';
    };

    utilsSharedModulesDirectory = mkOption {
      default = "${requireConfigRoot}/utils-shared-modules";
      defaultText = lib.literalExpression "\"\${config-manager.root}/utils-shared-modules\"";
      type = types.pathInStore;
      description = ''
        The directory containing modules shared with all configurations.
      '';
    };

    home = homeConfigurationOptions;
    nixos = nixosConfigurationOptions;
    macos = macosConfigurationOptions;
  };

  defaults = {
    hostSettings = mkDefaultOptions hostOptionsSubmodule.options;
    userSettings = mkDefaultOptions userOptionsSubmodule.options;
  };
}
