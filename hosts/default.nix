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

  options = systemsModulePath + /options; # options for system configuration.
  shared = systemsModulePath + /shared; # shared modules across all hosts.

  # home-manager
  users = ../users; # home-manager configurations.

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

  mkHost = host: builder: {
    system,
    moduleTrees ? [options shared users],
    roles ? [],
    extraModules ? [],
  } @ args': let
    hostname = builtins.baseNameOf host;
  in {
    ${hostname} = builder {
      inherit hostname system withSystem;
      modules = mkModulesForHost host {
        inherit moduleTrees roles extraModules;
      };
    };
  };

  mkHostAttrs = hosts: builtins.foldl' recursiveUpdate {} hosts;
in {
  flake.darwinConfigurations = let
    hm = inputs.home-manager.darwinModules.home-manager; # home-manager darwin module
  in
    mkHostAttrs [
      (mkHost ./darwin/mbp mkDarwinSystem {
        system = "aarch64-darwin";
        roles = [darwin];
        extraModules = [hm];
      })

      (mkHost ./darwin/studio mkDarwinSystem {
        system = "aarch64-darwin";
        roles = [darwin];
        extraModules = [hm];
      })
    ];

  flake.homeConfigurations = mkHostAttrs [
    (mkHost (./home + "/delay@linode") mkStandaloneHome {
      system = "x86_64-linux";
      roles = [home];
    })
  ];

  flake.nixosConfigurations = let
    hm = inputs.home-manager.nixosModules.home-manager; # home-manager nixos module
  in
    mkHostAttrs [
      (mkHost ./nixos/vm-aarch64 mkNixosSystem {
        system = "aarch64-linux";
        roles = [nixos];
        extraModules = [hm];
      })

      (mkHost ./nixos/vm-linode mkNixosSystem {
        system = "x86_64-linux";
        roles = [nixos];
        extraModules = [hm];
      })
    ];
}
