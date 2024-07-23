{
  config,
  inputs,
  lib,
  ...
}: let
  inherit (builtins) pathExists readDir readFileType;
  inherit (lib.strings) hasSuffix removeSuffix;

  options = import ./config-manager-options.nix {inherit config lib;};
  cfg = config.config-manager;

  # TODO: consider adding options to pass in the user's inputs name.
  requireInput = name: lib.throwIfNot (inputs ? ${name}) "Missing input: '${name}'" inputs.${name};
  requireDarwinInput = requireInput "darwin";
  requireNixpkgsInput = requireInput "nixpkgs";
  requireHomeManagerInput = requireInput "home-manager";

  crawlModuleDir = dir:
    lib.optionalAttrs (pathExists dir && readFileType dir == "directory")
    (lib.mapAttrs' (
        entry: type: let
          moduleAsSubdirWithDefault = "${dir}/${entry}/default.nix";
        in
          if (type == "regular" && hasSuffix ".nix" entry)
          then lib.nameValuePair (removeSuffix ".nix" entry) "${dir}/${entry}"
          else if (pathExists moduleAsSubdirWithDefault && readFileType moduleAsSubdirWithDefault == "regular")
          then lib.nameValuePair entry moduleAsSubdirWithDefault
          else lib.warn "Unexpected module shape: ${entry}" {}
      )
      (readDir dir));

  # Crawls the home-configs-modules/ and home-shared-modules/ directories (or
  # whichever directory specified by the config) and generates all standalone
  # home-manager configurations.
  mkHomeConfigurations = {
    hosts, # The list of user-defined hosts (i.e. from the flake config).
    defaults, # Default configuration values.
    configModules, # The list of user-provided configurations under home-config-modules/.
    systemModules, # The list of user-provided modules under home-shared-modules/ injected in each home configuration module.
    globalModules, # The list of user-provided utility modules under globals/ injected into all configuration modules.
    usersModules, # The list of user-provided user modules under users/ injected into all system configuration modules.
    importedModules, # The list of user-provided modules passed to this config via the `imports` option.
  }:
    lib.mapAttrs (name: hmConfigModule: let
      host = hosts.${name} or defaults;
      inherit (host) system user;

      supportedSystems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      throwForUnsupportedSystems = expr:
        lib.throwIfNot (builtins.elem system supportedSystems) "Unsupported system '${system}'" expr;
    in
      throwForUnsupportedSystems (requireHomeManagerInput.lib.homeManagerConfiguration {
        pkgs = import requireNixpkgsInput {inherit system;};
        extraSpecialArgs = {
          inherit inputs;
          globalModules = globalModules // importedModules.globalModules;
          systemModules = systemModules // importedModules.systemModules;
        };
        # NOTE: automatically backing up existing files is currently unsupported
        # for standalone home-manager setups.
        # See https://github.com/nix-community/home-manager/issues/5649.
        # Instead, we the `-b <backup-file-extension>` to `home-manager switch`.
        # TODO: contribute support, or find an alternative.
        # backupFileExtension = cfg.backupFileExtension;
        modules = [
          # System options.
          {nixpkgs.overlays = cfg.overlays ++ importedModules.overlays;}

          # Default home-manager configuration, if any.
          systemModules.default or {}
          # Default imported home-manager configuration, if any.
          importedModules.systemModules.default or {}

          # home-manager configuration.
          hmConfigModule
          configModules.default or {}

          # User configuration.
          # TODO: consider failing if the user configuration and default are both missing.
          usersModules.${user} or usersModules.default or {}
          importedModules.usersModules.${user} or importedModules.usersModules.default or {}
        ];
      }))
    configModules;

  # Creates specialized configuration factory functions.
  mkMkSystemConfigurations = {
    mkSystem,
    mkSystemHomeManagerModule,
  }: {
    hosts, # The list of user-defined hosts (i.e. from the flake config).
    defaults, # Default configuration values.
    configModules, # The list of user-provided configurations under (darwin|nixos)-config-modules/.
    systemModules, # The list of user-provided modules under (darwin|nixos)-shared-modules/ injected in each system configuration module.
    globalModules, # The list of user-provided utility modules under globals/ injected into all configuration modules.
    usersModules, # The list of user-provided user modules under users/ injected into all system configuration modules.
    importedModules, # The list of user-provided modules passed to this config via the `imports` option.
  }:
    lib.mapAttrs (hostname: systemConfigModule: let
      host = hosts.${hostname} or defaults;
      inherit (host) user;
    in
      mkSystem {
        specialArgs = {
          inherit inputs host;
          globalModules = globalModules // importedModules.globalModules;
          systemModules = systemModules // importedModules.systemModules;
        };
        modules = [
          # System options.
          {nixpkgs.overlays = cfg.overlays ++ importedModules.overlays;}

          # Default system configuration, if any.
          systemModules.default or {}
          # Default imported system configuration, if any.
          importedModules.systemModules.default or {}

          # System configuration.
          systemConfigModule
          configModules.default or {}
          importedModules.configModules.default or {}

          # User configuration.
          mkSystemHomeManagerModule
          {
            home-manager.extraSpecialArgs = {
              inherit inputs;
              globalModules = globalModules // importedModules.globalModules;
            };
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = cfg.backupFileExtension;
            # TODO: consider failing if the user configuration and default are both missing.
            home-manager.users.${user}.imports = [
              usersModules.${user} or usersModules.default or {}
              importedModules.usersModules.${user} or importedModules.usersModules.default or {}
            ];
          }
        ];
      })
    configModules;

  mkDarwinConfigurations = mkMkSystemConfigurations {
    mkSystem = requireDarwinInput.lib.darwinSystem;
    mkSystemHomeManagerModule = requireHomeManagerInput.darwinModules.home-manager;
  };

  mkNixosConfigurations = mkMkSystemConfigurations {
    mkSystem = requireNixpkgsInput.lib.nixosSystem;
    mkSystemHomeManagerModule = requireHomeManagerInput.nixosModules.home-manager;
  };
in {
  options = {inherit (options) config-manager;};

  config.flake = {
    homeConfigurations = mkHomeConfigurations {
      inherit (cfg.home) hosts;
      defaults = options.defaults.home;
      configModules = crawlModuleDir cfg.home.configModulesDirectory;
      systemModules = crawlModuleDir cfg.home.sharedModulesDirectory;
      globalModules = crawlModuleDir cfg.globalModulesDirectory;
      usersModules = crawlModuleDir cfg.usersModulesDirectory;
      importedModules = with cfg.imports; {
        # TODO: consider moving `overlays` out of the `importedModules`.
        inherit overlays globalModules usersModules;
        configModules = homeConfigModules;
        systemModules = homeSharedModules;
      };
    };

    darwinConfigurations = mkDarwinConfigurations {
      inherit (cfg.darwin) hosts;
      defaults = options.defaults.darwin;
      configModules = crawlModuleDir cfg.darwin.configModulesDirectory;
      systemModules = crawlModuleDir cfg.darwin.sharedModulesDirectory;
      globalModules = crawlModuleDir cfg.globalModulesDirectory;
      usersModules = crawlModuleDir cfg.usersModulesDirectory;
      importedModules = with cfg.imports; {
        # TODO: consider moving `overlays` out of the `importedModules`.
        inherit overlays globalModules usersModules;
        configModules = darwinConfigModules;
        systemModules = darwinSharedModules;
      };
    };

    nixosConfigurations = mkNixosConfigurations {
      inherit (cfg.nixos) hosts;
      defaults = options.defaults.nixos;
      configModules = crawlModuleDir cfg.nixos.configModulesDirectory;
      systemModules = crawlModuleDir cfg.nixos.sharedModulesDirectory;
      globalModules = crawlModuleDir cfg.globalModulesDirectory;
      usersModules = crawlModuleDir cfg.usersModulesDirectory;
      importedModules = with cfg.imports; {
        # TODO: consider moving `overlays` out of the `importedModules`.
        inherit overlays globalModules usersModules;
        configModules = nixosConfigModules;
        systemModules = nixosSharedModules;
      };
    };

    # NOTE: for debug purposes only.
    # TODO: remove once the options structure is final~ish.
    inherit cfg;

    config-manager = lib.mkIf (!cfg.final) {
      overlays = cfg.overlays;
      homeConfigModules = crawlModuleDir cfg.home.configModulesDirectory;
      homeSharedModules = crawlModuleDir cfg.home.sharedModulesDirectory;
      darwinConfigModules = crawlModuleDir cfg.darwin.configModulesDirectory;
      darwinSharedModules = crawlModuleDir cfg.darwin.sharedModulesDirectory;
      nixosConfigModules = crawlModuleDir cfg.nixos.configModulesDirectory;
      nixosSharedModules = crawlModuleDir cfg.nixos.sharedModulesDirectory;
      globalModules = crawlModuleDir cfg.globalModulesDirectory;
      # TODO: consider if `usersModules` should even be exported here?
      usersModules = crawlModuleDir cfg.usersModulesDirectory;
    };
  };
}
