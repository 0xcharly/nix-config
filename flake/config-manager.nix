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

  # Crawls the home-configurations/ and home-modules/ directories (or whichever
  # directory specified by the config) and generate all standalone home-manager
  # configurations.
  mkHomeConfigurations = {
    users, # The list of user-defined users (i.e. from the flake config).
    hmConfigModules, # The list of user-provided modules under home-configurations/.
    hmSharedModules, # The list of user-provided modules under home-modules/ injected in each home configuration module.
    hmModulesInjectArgs, # Extra parameters to pass to all home configurations.
  }:
    lib.mapAttrs (name: homeConfigModule: let
      userSettings = users.${name} or options.defaults.userSettings;
      inherit (userSettings) system;

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
          {inherit hmSharedModules;}
          // cfg.injectArgs
          // hmModulesInjectArgs
          // userSettings.injectArgs;
        # backupFileExtension = hostSettings.homeManagerBackupFileExtension;
        modules = [
          # System options.
          {nixpkgs.overlays = cfg.overlays;}

          # Default user configuration, if any.
          hmSharedModules.default or {}

          # User configuration.
          homeConfigModule
        ];
      }))
    hmConfigModules;

  # Creates specialized configuration factory functions.
  mkMkSystemConfigurations = {
    mkSystem,
    mkSystemHomeManagerModule,
  }: {
    users, # The list of user-defined users (i.e. from the flake config).
    hosts, # The list of user-defined hosts (i.e. from the flake config).
    osConfigModules, # The list of user-provided configurations under (macos|nixos)-configurations/.
    osSharedModules, # The list of user-provided modules under (macos|nixos)-modules/ injected in each system configuration module.
    hmConfigModules, # The list of user-provided modules under home-configurations/.
    hmSharedModules, # The list of user-provided modules under home-modules/ injected in each home configuration module.
    osModulesInjectArgs, # Extra parameters to pass to all system configurations.
    hmModulesInjectArgs, # Extra parameters to pass to all home configurations.
  }:
    lib.mapAttrs (name: hostConfigModule: let
      hostSettings = hosts.${name} or options.defaults.hostSettings;
      userSettings = users.${name} or options.defaults.userSettings;
    in
      mkSystem {
        specialArgs =
          {inherit osSharedModules;}
          // cfg.injectArgs
          // osModulesInjectArgs
          // hostSettings.injectArgs
          // hostSettings.osInjectArgs;
        modules = [
          # System options.
          {nixpkgs.overlays = cfg.overlays;}

          # Default system configuration, if any.
          osSharedModules.default or {}

          # System configuration.
          hostConfigModule

          # User configuration.
          mkSystemHomeManagerModule
          {
            home-manager.extraSpecialArgs =
              {inherit hmSharedModules;}
              // cfg.injectArgs
              // hmModulesInjectArgs
              // userSettings.injectArgs
              // hostSettings.injectArgs
              // hostSettings.hmInjectArgs;
            # TODO: check if these options are required.
            # home-manager.useGlobalPkgs = true;
            # home-manager.useUserPackages = true;
            home-manager.backupFileExtension = hostSettings.hmBackupFileExtension;
            home-manager.users.${hostSettings.user} = import hmConfigModules.${hostSettings.user};
          }
        ];
      })
    osConfigModules;

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
      inherit (cfg.home) users;
      hmConfigModules = crawlModuleDir cfg.home.configModulesDirectory;
      hmSharedModules = crawlModuleDir cfg.home.sharedModulesDirectory;
      hmModulesInjectArgs = cfg.home.injectArgs;
    };

    darwinConfigurations = mkDarwinConfigurations {
      inherit (cfg.home) users;
      inherit (cfg.macos) hosts;
      osConfigModules = crawlModuleDir cfg.macos.configModulesDirectory;
      osSharedModules = crawlModuleDir cfg.macos.sharedModulesDirectory;
      hmConfigModules = crawlModuleDir cfg.home.configModulesDirectory;
      hmSharedModules = crawlModuleDir cfg.home.sharedModulesDirectory;
      osModulesInjectArgs = cfg.macos.injectArgs;
      hmModulesInjectArgs = cfg.home.injectArgs;
    };

    nixosConfigurations = mkNixosConfigurations {
      inherit (cfg.home) users;
      inherit (cfg.nixos) hosts;
      osConfigModules = crawlModuleDir cfg.nixos.configModulesDirectory;
      osSharedModules = crawlModuleDir cfg.nixos.sharedModulesDirectory;
      hmConfigModules = crawlModuleDir cfg.home.configModulesDirectory;
      hmSharedModules = crawlModuleDir cfg.home.sharedModulesDirectory;
      osModulesInjectArgs = cfg.nixos.injectArgs;
      hmModulesInjectArgs = cfg.home.injectArgs;
    };
  };
}
