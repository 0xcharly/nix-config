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

  config = systemsModulePath + /config; # options for system configuration.
  shared = systemsModulePath + /shared; # shared modules across all hosts.
  # TODO: find a better name for modules that are for "non-hm-standalone" installs.
  managed = systemsModulePath + /system; # shared modules across NixOS/darwin.

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
    system ? "aarch64-darwin",
    moduleTrees ? [],
    roles ? [],
    extraModules ? [],
    ...
  } @ args': let
    hm = inputs.home-manager.darwinModules.home-manager; # home-manager darwin module
  in
    mkHost (args'
      // {
        inherit host system;
        builder = mkDarwinSystem;
        moduleTrees = moduleTrees ++ [config managed shared users];
        roles = roles ++ [darwin];
        extraModules = extraModules ++ [hm];
      });

  mkHomeHost = host: {
    # TODO: use and propagate instead of hardcoding it in `standalone.nix`.
    username ? "delay",
    system ? "x86_64-linux",
    moduleTrees ? [],
    roles ? [],
    extraModules ? [],
    ...
  } @ args':
    mkHost (args'
      // {
        inherit host system;
        builder = mkStandaloneHome;
        moduleTrees = moduleTrees ++ [config shared];
        roles = roles ++ [home];
        extraModules = extraModules ++ [(import standalone username)];
      });

  mkNixosHost = host: {
    system,
    moduleTrees ? [],
    roles ? [],
    extraModules ? [],
    ...
  } @ args': let
    hm = inputs.home-manager.nixosModules.home-manager; # home-manager nixos module
  in
    mkHost (args'
      // {
        inherit host system;
        builder = mkNixosSystem;
        moduleTrees = moduleTrees ++ [config managed shared users];
        roles = roles ++ [nixos];
        extraModules = extraModules ++ [hm];
      });

  mkHostAttrs = builtins.foldl' recursiveUpdate {};
in {
  flake.lib = {
    inherit mkDarwinHost mkHomeHost mkNixosHost mkHostAttrs;
  };

  flake.darwinConfigurations = mkHostAttrs [
    (mkDarwinHost ./darwin/mbp {})
    (mkDarwinHost ./darwin/studio {})
  ];

  flake.homeConfigurations = mkHostAttrs [
    (mkHomeHost (./home + "/delay@linode") {})
  ];

  flake.nixosConfigurations = mkHostAttrs [
    (mkNixosHost ./nixos/vm-aarch64 {system = "aarch64-linux";})
    (mkNixosHost ./nixos/vm-linode {system = "x86_64-linux";})
  ];
}
