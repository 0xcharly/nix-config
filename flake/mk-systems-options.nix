{
  config,
  lib,
}: let
  inherit (lib) mkOption mkOptionType types;
  cfg = config.mkSystems;

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
        The default system to use for this user configurations.
      '';
    };
  };

  mkConfigDirectoriesOptions = prefix: let
    supportedPrefixes = [
      "darwin"
      "home"
      "nixos"
    ];
    throwForUnsupportedPrefix = expr:
      lib.throwIfNot (builtins.elem prefix supportedPrefixes) "Internal error: unsupported prefix '${prefix}'" expr;
    requireConfigRoot = lib.throwIfNot (cfg ? root) "mkSystems.root must be set" cfg.root;
  in
    throwForUnsupportedPrefix {
      modulesDirectory = mkOption {
        default = "${requireConfigRoot}/${prefix}-modules";
        defaultText = lib.literalExpression "\"\${mkSystems.root}/${prefix}-modules\"";
        type = types.pathInStore;
        description = ''
          The directory containing ${prefix}Modules.
        '';
      };

      configurationsDirectory = mkOption {
        default = "${requireConfigRoot}/${prefix}-configurations";
        defaultText = lib.literalExpression "\"\${mkSystems.root}/${prefix}-configurations\"";
        type = types.pathInStore;
        description = ''
          The directory containing ${prefix}Configurations.
        '';
      };
    };

  hostOptionsSubmodule.options = {
    user = mkOption {
      default = "delay";
      type = types.str;
      description = ''
        The name of the owning user.
      '';
    };

    homeManagerBackupFileExtension = mkOption {
      type = types.nullOr types.str;
      default = "nix-backup";
      example = "nix-backup";
      description = ''
        On activation move existing files by appending the given file
        extension rather than exiting with an error.
      '';
    };

    injectArgs = mkOption {
      default = {};
      type = types.attrsOf types.anything;
      description = ''
        Extra arguments to pass to this host's system and home configuration.
      '';
    };

    sysInjectArgs = mkOption {
      default = {};
      type = types.attrsOf types.anything;
      description = ''
        Extra arguments to pass to this host's system configuration.
      '';
    };

    usrInjectArgs = mkOption {
      default = {};
      type = types.attrsOf types.anything;
      description = ''
        Extra arguments to pass to this host's home configuration.
      '';
    };
  };

  mkSystemConfigurationOptions = system: let
    supportedSystems = ["darwin" "nixos"];
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
    mkConfigDirectoriesOptions "nixos"
    // mkSystemConfigurationOptions "nixos";

  darwinConfigurationOptions =
    mkConfigDirectoriesOptions "darwin"
    // mkSystemConfigurationOptions "darwin";

  homeConfigurationOptions =
    mkConfigDirectoriesOptions "home"
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
  mkSystems = {
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

    globalArgs = mkOption {
      default = {};
      example = lib.literalExpression "{ inherit inputs; }";
      type = types.attrsOf types.anything;
      description = ''
        Extra arguments to pass to all configurations.
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
