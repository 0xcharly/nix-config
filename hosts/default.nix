{
  withSystem,
  inputs,
  ...
}: let
  # `self.usrlib` is an extended version of `nixpkgs.lib`.
  # mkDarwinSystem and mkNixosSystem are builders for assembling a new system.
  inherit (inputs.self.lib.user) mkNixosSystem;
  inherit (inputs.self.lib.user) mkModuleTree;
  inherit (inputs.nixpkgs.lib.attrsets) recursiveUpdate;
  inherit (inputs.nixpkgs.lib.lists) concatLists flatten singleton;

  # Specify root path for the modules. The concept is similar to modulesPath
  # that is found in nixpkgs, and is defined in case the modulePath changes
  # depth (i.e modules becomes nixos/modules).
  systemsModulePath = ../modules;

  config = systemsModulePath + /config; # options for system configuration.
  nixos = systemsModulePath + /nixos; # nixos-specific modules.
  shared = systemsModulePath + /shared; # shared modules across all hosts.
  fullyManaged = systemsModulePath + /system; # shared modules across NixOS/darwin.

  # home-manager
  users = ../users; # home-manager configurations.

  # mkModulesList generates a list of modules imported by the host with the given
  # hostname. Do note that this needs to be called *in* the (darwin|nixos)System
  # set, since it generates a *module list*, which is also expected by system
  # builders.
  mkModuleList = {
    hostModule,
    moduleTrees,
    extraModules,
  }:
    flatten (
      concatLists [
        # Derive host specific module path from the first argument of the
        # function.
        (singleton (hostModule + /host.nix))

        # Recursively import all module trees (i.e. directories with a
        # `module.nix`) for given moduleTree directories and roles.
        (builtins.map mkModuleTree moduleTrees)

        # And append any additional lists that don't don't conform to the
        # moduleTree API, but still need to be imported somewhat commonly.
        extraModules
      ]
    );

  mkHost = {
    hostModule,
    builder,
    system,
    moduleTrees ? [],
    extraModules ? [],
    ...
  } @ args: let
    hostname = builtins.baseNameOf hostModule;
  in {
    ${hostname} = builder (
      args
      // {
        inherit hostname system withSystem;
        modules = mkModuleList {inherit hostModule moduleTrees extraModules;};
      }
    );
  };

  mkNixosHost = {moduleTrees ? [], ...} @ args:
    mkHost (args
      // {
        system = "x86_64-linux";
        builder = mkNixosSystem;
        moduleTrees = moduleTrees ++ [config nixos fullyManaged shared users];
      });

  mkConfigurations = builtins.foldl' recursiveUpdate {};
in {
  flake = {
    nixosConfigurations = mkConfigurations [
      (mkNixosHost {hostModule = ./nixos/heimdall;})
    ];
  };

  imports = [./hive-deploy.nix];
}
