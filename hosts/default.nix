{
  withSystem,
  inputs,
  ...
}: let
  # `self.usrlib` is an extended version of `nixpkgs.lib`.
  # mkDarwinSystem and mkNixosSystem are builders for assembling a new system.
  inherit (inputs.self.usrlib.builders) mkDarwinSystem mkNixosSystem mkStandaloneHome;
  inherit (inputs.self.usrlib.modules) mkModuleTree;
  inherit (inputs.nixpkgs.lib.attrsets) recursiveUpdate;
  inherit (inputs.nixpkgs.lib.lists) concatLists flatten singleton;

  # Specify root path for the modules. The concept is similar to modulesPath
  # that is found in nixpkgs, and is defined in case the modulePath changes
  # depth (i.e modules becomes nixos/modules).
  systemsModulePath = ../modules;

  darwin = systemsModulePath + /darwin; # darwin-specific modules.
  home = systemsModulePath + /home; # standalone-specific modules.
  nixos = systemsModulePath + /nixos; # nixos-specific modules.
  iso = systemsModulePath + /iso; # nixos-specific modules for creating an ISO.

  config = systemsModulePath + /config; # options for system configuration.
  shared = systemsModulePath + /shared; # shared modules across all hosts.
  fullyManaged = systemsModulePath + /system; # shared modules across NixOS/darwin.

  # home-manager
  users = ../users; # home-manager configurations.
  standalone = users + /standalone.nix;

  # mkModulesFor generates a list of modules imported by the host with the given
  # hostname. Do note that this needs to be called *in* the (darwin|nixos)System
  # set, since it generates a *module list*, which is also expected by system
  # builders.
  mkModulesForHost = host: {
    moduleTrees,
    roles,
    extraModules,
  }:
    flatten (
      concatLists [
        # Derive host specific module path from the first argument of the
        # function.
        (singleton (host + /host.nix))

        # Recursively import all module trees (i.e. directories with a
        # `module.nix`) for given moduleTree directories and roles.
        (map mkModuleTree (concatLists [moduleTrees roles]))

        # And append any additional lists that don't don't conform to the
        # moduleTree API, but still need to be imported somewhat commonly.
        extraModules
      ]
    );

  mkHost = {
    host,
    builder,
    system,
    moduleTrees,
    roles,
    extraModules,
    ...
  } @ args': let
    hostname = builtins.baseNameOf host;
  in {
    ${hostname} = builder (args'
      // {
        inherit hostname system withSystem;
        modules = mkModulesForHost host {
          inherit moduleTrees roles extraModules;
        };
      });
  };

  mkDarwinHost = host: {
    moduleTrees ? [],
    roles ? [],
    extraModules ? [],
    ...
  } @ args':
    mkHost (args'
      // {
        inherit extraModules host;
        system = "aarch64-darwin";
        builder = mkDarwinSystem;
        moduleTrees = moduleTrees ++ [config fullyManaged shared users];
        roles = roles ++ [darwin];
      });

  mkHomeHost = host: {
    moduleTrees ? [],
    roles ? [],
    extraModules ? [],
    ...
  } @ args':
    mkHost (args'
      // {
        inherit host;
        system = "x86_64-linux";
        builder = mkStandaloneHome;
        moduleTrees = moduleTrees ++ [config shared];
        roles = roles ++ [home];
        extraModules = extraModules ++ [(import standalone "delay")];
      });

  mkNixosHost = host: {
    moduleTrees ? [],
    roles ? [],
    extraModules ? [],
    ...
  } @ args':
    mkHost (args'
      // {
        inherit extraModules host;
        system = "x86_64-linux";
        builder = mkNixosSystem;
        moduleTrees = moduleTrees ++ [config fullyManaged shared users];
        roles = roles ++ [nixos];
      });

  mkNixosIso = host: {
    moduleTrees ? [],
    roles ? [],
    extraModules ? [],
    ...
  } @ args':
    mkHost (args'
      // {
        inherit extraModules host;
        system = "x86_64-linux";
        builder = mkNixosSystem;
        moduleTrees = moduleTrees ++ [config shared];
        roles = roles ++ [iso];
      });

  mkHostAttrs = builtins.foldl' recursiveUpdate {};
in {
  flake.lib = {
    inherit mkDarwinHost mkHomeHost mkHostAttrs;
  };

  flake.darwinConfigurations = mkHostAttrs [
    (mkDarwinHost ./darwin/mbp {})
  ];

  flake.homeConfigurations = mkHostAttrs [
    (mkHomeHost (./home + "/delay@linode") {})
  ];

  flake.nixosConfigurations = mkHostAttrs [
    (mkNixosIso ./iso/recovery {})

    (mkNixosHost ./nixos/heimdall {})
    (mkNixosHost ./nixos/linode {})
    (mkNixosHost ./nixos/nyx {})
    (mkNixosHost ./nixos/helios {})
    (mkNixosHost ./nixos/selene {})
  ];
}
