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
    users, # The list of user-defined users (i.e. from the flake config).
    hmConfigModules, # The list of user-provided configurations under home-config-modules/.
    hmSharedModules, # The list of user-provided modules under home-shared-modules/ injected in each home configuration module.
    utilsSharedModules, # The list of user-provided utility modules under utils-shared-modules/ injected into all configuration modules.
  }:
    lib.mapAttrs (name: userSettings: let
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
        extraSpecialArgs = {inherit inputs hmSharedModules utilsSharedModules;};
        # backupFileExtension = hostSettings.hmBackupFileExtension;
        modules = [
          # System options.
          {nixpkgs.overlays = cfg.overlays;}

          # Default user configuration, if any.
          hmSharedModules.default or {}

          # User configuration.
          # TODO: consider failing if the user configuration and default are both missing.
          hmConfigModules.${name} or hmConfigModules.default or {}
        ];
      }))
    users;

  # Creates specialized configuration factory functions.
  mkMkSystemConfigurations = {
    mkSystem,
    mkSystemHomeManagerModule,
  }: {
    hosts, # The list of user-defined hosts (i.e. from the flake config).
    osConfigModules, # The list of user-provided configurations under (macos|nixos)-config-modules/.
    osSharedModules, # The list of user-provided modules under (macos|nixos)-shared-modules/ injected in each system configuration module.
    hmConfigModules, # The list of user-provided configurations under home-config-modules/.
    hmSharedModules, # The list of user-provided modules under home-shared-modules/ injected in each home configuration module.
    utilsSharedModules, # The list of user-provided utility modules under utils-shared-modules/ injected into all configuration modules.
  }:
    lib.mapAttrs (hostname: hostSettings: let
      username = hostSettings.user;
    in
      mkSystem {
        specialArgs = {inherit inputs hostSettings osSharedModules utilsSharedModules;};
        modules = [
          # System options.
          {nixpkgs.overlays = cfg.overlays;}

          # Default system configuration, if any.
          osSharedModules.default or {}

          # System configuration.
          osConfigModules.${hostname} or osConfigModules.default or {}

          # User configuration.
          # TODO: consider failing if the user configuration and default are both missing.
          mkSystemHomeManagerModule
          {
            home-manager.extraSpecialArgs = {inherit inputs hmSharedModules utilsSharedModules;};
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = hostSettings.hmBackupFileExtension;
            # TODO: consider failing if the user configuration and default are both missing.
            home-manager.users.${username}.imports = [(hmConfigModules.${username} or hmConfigModules.default or {})];
          }
        ];
      })
    hosts;

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
      utilsSharedModules = crawlModuleDir cfg.utilsSharedModulesDirectory;
    };

    darwinConfigurations = mkDarwinConfigurations {
      inherit (cfg.macos) hosts;
      osConfigModules = crawlModuleDir cfg.macos.configModulesDirectory;
      osSharedModules = crawlModuleDir cfg.macos.sharedModulesDirectory;
      hmConfigModules = crawlModuleDir cfg.home.configModulesDirectory;
      hmSharedModules = crawlModuleDir cfg.home.sharedModulesDirectory;
      utilsSharedModules = crawlModuleDir cfg.utilsSharedModulesDirectory;
    };

    nixosConfigurations = mkNixosConfigurations {
      inherit (cfg.nixos) hosts;
      osConfigModules = crawlModuleDir cfg.nixos.configModulesDirectory;
      osSharedModules = crawlModuleDir cfg.nixos.sharedModulesDirectory;
      hmConfigModules = crawlModuleDir cfg.home.configModulesDirectory;
      hmSharedModules = crawlModuleDir cfg.home.sharedModulesDirectory;
      utilsSharedModules = crawlModuleDir cfg.utilsSharedModulesDirectory;
    };
  };
}
