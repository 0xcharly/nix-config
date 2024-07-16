{
  config,
  inputs,
  lib,
  ...
}: let
  inherit (builtins) pathExists readDir readFileType;
  inherit (lib.strings) hasSuffix removeSuffix;

  options = import ./mk-systems-options.nix {inherit config lib;};
  cfg = config.mkSystems;

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
          then lib.attrsets.nameValuePair (removeSuffix ".nix" entry) "${dir}/${entry}"
          else if (pathExists moduleAsSubdirWithDefault && readFileType moduleAsSubdirWithDefault == "regular")
          then lib.attrsets.nameValuePair entry moduleAsSubdirWithDefault
          else lib.warn "Unexpected module shape: ${entry}" {}
      )
      (readDir dir));

  # Crawls the home-configurations/ and home-modules/ directories (or whichever
  # directory specified by the config) and generate all standalone home-manager
  # configurations.
  mkHomeConfigurations = {
    users, # The list of user-defined users (i.e. from the flake config).
    usrConfigs, # The list of user-provided modules under home-configurations/.
    usrModules, # The list of user-provided modules under home-modules/ injected in each home configuration module.
    usrModulesInjectArgs, # Extra parameters to pass to all home configurations.
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
          {inherit usrModules;}
          // cfg.globalArgs
          // usrModulesInjectArgs
          // userSettings.injectArgs;
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

  # Creates specialized configuration factory functions.
  mkMkSystemConfigurations = {
    mkSystem,
    mkSystemHomeManagerModule,
  }: {
    users, # The list of user-defined users (i.e. from the flake config).
    hosts, # The list of user-defined hosts (i.e. from the flake config).
    sysConfigs, # The list of user-provided configurations under (darwin|nixos)-configurations/.
    sysModules, # The list of user-provided modules under (darwin|nixos)-modules/ injected in each system configuration module.
    usrConfigs, # The list of user-provided modules under home-configurations/.
    usrModules, # The list of user-provided modules under home-modules/ injected in each home configuration module.
    sysModulesInjectArgs, # Extra parameters to pass to all system configurations.
    usrModulesInjectArgs, # Extra parameters to pass to all home configurations.
  }:
    lib.mapAttrs (name: hostConfigModule: let
      hostSettings = hosts.${name} or options.defaults.hostSettings;
      userSettings = users.${name} or options.defaults.userSettings;
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
              // userSettings.injectArgs
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

  mkDarwinConfigurations = mkMkSystemConfigurations {
    mkSystem = requireDarwinInput.lib.darwinSystem;
    mkSystemHomeManagerModule = requireHomeManagerInput.darwinModules.home-manager;
  };

  mkNixosConfigurations = mkMkSystemConfigurations {
    mkSystem = requireNixpkgsInput.lib.nixosSystem;
    mkSystemHomeManagerModule = requireHomeManagerInput.nixosModules.home-manager;
  };
in {
  options = {inherit (options) mkSystems;};

  config.flake = {
    homeConfigurations = mkHomeConfigurations {
      inherit (cfg.home) users;
      usrConfigs = crawlModuleDir cfg.home.configurationsDirectory;
      usrModules = crawlModuleDir cfg.home.modulesDirectory;
      usrModulesInjectArgs = cfg.home.injectArgs;
    };

    darwinConfigurations = mkDarwinConfigurations {
      inherit (cfg.home) users;
      inherit (cfg.darwin) hosts;
      sysConfigs = crawlModuleDir cfg.darwin.configurationsDirectory;
      sysModules = crawlModuleDir cfg.darwin.modulesDirectory;
      usrConfigs = crawlModuleDir cfg.home.configurationsDirectory;
      usrModules = crawlModuleDir cfg.home.modulesDirectory;
      sysModulesInjectArgs = cfg.darwin.injectArgs;
      usrModulesInjectArgs = cfg.home.injectArgs;
    };

    nixosConfigurations = mkNixosConfigurations {
      inherit (cfg.home) users;
      inherit (cfg.nixos) hosts;
      sysConfigs = crawlModuleDir cfg.nixos.configurationsDirectory;
      sysModules = crawlModuleDir cfg.nixos.modulesDirectory;
      usrConfigs = crawlModuleDir cfg.home.configurationsDirectory;
      usrModules = crawlModuleDir cfg.home.modulesDirectory;
      sysModulesInjectArgs = cfg.nixos.injectArgs;
      usrModulesInjectArgs = cfg.home.injectArgs;
    };
  };
}
