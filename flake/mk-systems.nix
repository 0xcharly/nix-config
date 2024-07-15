{
  inputs,
  lib,
  config,
  ...
}: let
  inherit (builtins) pathExists readDir readFileType;
  inherit (lib) mkOption mkOptionType types;
  inherit (lib.strings) hasSuffix removeSuffix;
  cfg = config.mkSystems;

  # TODO: consider adding options to pass in the user's inputs name.
  requireInput = name: lib.throwIfNot (inputs ? ${name}) "Missing input: '${name}'" inputs.${name};
  requireDarwinInput = requireInput "darwin";
  requireNixpkgsInput = requireInput "nixpkgs";
  requireHomeManagerInput = requireInput "home-manager";

  mkDefaultOptions = options: let
    requireDefault = name: value: lib.throwIfNot (value ? default) "Internal error: missing default value for option '${name}" value.default;
  in
    lib.mapAttrs (name: value: requireDefault name value) options;

  crawlModuleDir = dir:
    lib.optionalAttrs (pathExists dir && readFileType dir == "directory")
    (lib.mapAttrs' (
        entry: type: let
          moduleAsSubdirWithDefault = "${dir}/${entry}/default.nix";
        in
          if (type == "regular" && hasSuffix ".nix" entry)
          then lib.attrsets.nameValuePair (removeSuffix ".nix" entry) "${dir}/${entry}"
          else if (pathExists moduleAsSubdirWithDefault && readFileType moduleAsSubdirWithDefault == "regular")
          then lib.attrsets.nameValuePair entry moduleAsSubdirWithDefault
          else lib.warn "Unexpected module shape: ${entry}" {}
      )
      (readDir dir));

  overlayType = mkOptionType {
    name = "nixpkgs-overlay";
    description = "nixpkgs overlay";
    check = lib.isFunction;
    merge = lib.mergeOneOption;
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

  mkSystemConfigurationsGenerator = {
    mkSystem,
    mkSystemHomeManagerModule,
  }: {
    hosts, # The list of user-defined hosts (i.e. from the flake config).
    sysConfigs, # The list of user-provided configurations under (darwin|nixos)-configurations/.
    sysModules, # The list of user-provided modules under (darwin|nixos)-modules/ injected in each system configuration module.
    usrConfigs, # The list of user-provided modules under home-configurations/.
    usrModules, # The list of user-provided modules under home-modules/ injected in each home configuration module.
    sysModulesInjectArgs, # Extra parameters to pass to all system configurations.
    usrModulesInjectArgs, # Extra parameters to pass to all home configurations.
  }:
    lib.mapAttrs (name: hostConfigModule: let
      hostSettings = hosts.${name} or mkDefaultOptions hostOptionsSubmodule.options;
    in
      mkSystem {
        specialArgs =
          {inherit sysModules;}
          // cfg.globalArgs
          // sysModulesInjectArgs
          // hostSettings.injectArgs
          // hostSettings.sysInjectArgs;
        modules = [
          # System options.
          {nixpkgs.overlays = cfg.overlays;}

          # Default system configuration, if any.
          sysModules.default or {}

          # System configuration.
          hostConfigModule

          # User configuration.
          mkSystemHomeManagerModule
          {
            home-manager.extraSpecialArgs =
              {inherit usrModules;}
              // cfg.globalArgs
              // usrModulesInjectArgs
              // hostSettings.injectArgs
              // hostSettings.usrInjectArgs;
            # TODO: check if these options are required.
            # home-manager.useGlobalPkgs = true;
            # home-manager.useUserPackages = true;
            home-manager.backupFileExtension = hostSettings.homeManagerBackupFileExtension;
            home-manager.users.${hostSettings.user} = import usrConfigs.${hostSettings.user};
          }
        ];
      })
    sysConfigs;

  mkDarwinConfigurations = mkSystemConfigurationsGenerator {
    mkSystem = requireDarwinInput.lib.darwinSystem;
    mkSystemHomeManagerModule = requireHomeManagerInput.darwinModules.home-manager;
  };

  mkNixosConfigurations = mkSystemConfigurationsGenerator {
    mkSystem = requireNixpkgsInput.lib.nixosSystem;
    mkSystemHomeManagerModule = requireHomeManagerInput.nixosModules.home-manager;
  };

  mkHomeConfigurations = {
    users, # The list of user-defined users (i.e. from the flake config).
    usrConfigs, # The list of user-provided modules under home-configurations/.
    usrModules, # The list of user-provided modules under home-modules/ injected in each home configuration module.
    usrModulesInjectArgs, # Extra parameters to pass to all home configurations.
  }:
    lib.mapAttrs (name: homeConfigModule: let
      homeSettings = users.${name} or mkDefaultOptions userOptionsSubmodule.options;
      inherit (homeSettings) system;

      supportedSystems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      throwForUnsupportedSystems = expr:
        lib.throwIfNot (builtins.elem system supportedSystems) ("Unsupported system '" + system + "'") expr;
    in
      throwForUnsupportedSystems (requireHomeManagerInput.lib.homeManagerConfiguration {
        pkgs = import requireNixpkgsInput {inherit system;};
        extraSpecialArgs =
          {inherit usrModules;}
          // cfg.globalArgs
          // usrModulesInjectArgs
          // homeSettings.injectArgs;
        # backupFileExtension = hostSettings.homeManagerBackupFileExtension;
        modules = [
          # System options.
          {nixpkgs.overlays = cfg.overlays;}

          # Default user configuration, if any.
          usrModules.default or {}

          # User configuration.
          homeConfigModule
        ];
      }))
    usrConfigs;

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
in {
  options.mkSystems = {
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

  config.flake = {
    homeConfigurations = mkHomeConfigurations {
      inherit (cfg.home) users;
      usrConfigs = crawlModuleDir cfg.home.configurationsDirectory;
      usrModules = crawlModuleDir cfg.home.modulesDirectory;
      usrModulesInjectArgs = cfg.home.injectArgs;
    };

    darwinConfigurations = mkDarwinConfigurations {
      inherit (cfg.darwin) hosts;
      sysConfigs = crawlModuleDir cfg.darwin.configurationsDirectory;
      sysModules = crawlModuleDir cfg.darwin.modulesDirectory;
      usrConfigs = crawlModuleDir cfg.home.configurationsDirectory;
      usrModules = crawlModuleDir cfg.home.modulesDirectory;
      sysModulesInjectArgs = cfg.darwin.injectArgs;
      usrModulesInjectArgs = cfg.home.injectArgs;
      # inherit (cfg.home) users;
    };

    nixosConfigurations = mkNixosConfigurations {
      inherit (cfg.nixos) hosts;
      sysConfigs = crawlModuleDir cfg.nixos.configurationsDirectory;
      sysModules = crawlModuleDir cfg.nixos.modulesDirectory;
      usrConfigs = crawlModuleDir cfg.home.configurationsDirectory;
      usrModules = crawlModuleDir cfg.home.modulesDirectory;
      sysModulesInjectArgs = cfg.nixos.injectArgs;
      usrModulesInjectArgs = cfg.home.injectArgs;
      # inherit (cfg.home) users;
    };
  };
}
