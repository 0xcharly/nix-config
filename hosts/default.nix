{
  withSystem,
  inputs,
  ...
}: let
  # `self.usrlib` is an extended version of `nixpkgs.lib`.
  # mkDarwinSystem and mkNixosSystem are builders for assembling a new system.
  inherit (inputs.self.lib.user) mkDarwinSystem mkNixosSystem mkStandaloneHome;
  inherit (inputs.self.lib.user) mkModuleTree;
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

  # mkModulesList generates a list of modules imported by the host with the given
  # hostname. Do note that this needs to be called *in* the (darwin|nixos)System
  # set, since it generates a *module list*, which is also expected by system
  # builders.
  mkModuleList = {
    host,
    moduleTrees,
    extraModules,
  }:
    flatten (
      concatLists [
        # Derive host specific module path from the first argument of the
        # function.
        (singleton (host + /host.nix))

        # Recursively import all module trees (i.e. directories with a
        # `module.nix`) for given moduleTree directories and roles.
        (builtins.map mkModuleTree moduleTrees)

        # And append any additional lists that don't don't conform to the
        # moduleTree API, but still need to be imported somewhat commonly.
        extraModules
      ]
    );

  mkHost = {
    host,
    builder,
    system,
    moduleTrees ? [],
    extraModules ? [],
  }: let
    hostname = builtins.baseNameOf host;
  in {
    ${hostname} = builder {
      inherit hostname system withSystem;
      modules = mkModuleList {inherit host moduleTrees extraModules;};
    };
  };

  mkDarwinHost = host:
    mkHost {
      inherit host;
      system = "aarch64-darwin";
      builder = mkDarwinSystem;
      moduleTrees = [config darwin fullyManaged shared users];
    };

  mkHomeHost = host:
    mkHost {
      inherit host;
      system = "x86_64-linux";
      builder = mkStandaloneHome;
      moduleTrees = [config home shared];
      extraModules = [(import standalone "delay")];
    };

  mkNixosHost = host:
    mkHost {
      inherit host;
      system = "x86_64-linux";
      builder = mkNixosSystem;
      moduleTrees = [config nixos fullyManaged shared users];
    };

  mkNixosIso = host:
    mkHost {
      inherit host;
      system = "x86_64-linux";
      builder = mkNixosSystem;
      moduleTrees = [config iso shared];
    };

  mkHomeFromNixosHost = hostname: {
    ${hostname} = inputs.self.nixosConfigurations.${hostname}.config.home-manager.users.delay.home;
  };

  mkConfigurations = builtins.foldl' recursiveUpdate {};
in {
  flake = {
    # Export builder functions to build upon this config.
    fn = {inherit mkConfigurations mkDarwinHost mkHomeHost mkNixosHost mkNixosIso;};

    darwinConfigurations = mkConfigurations [
      (mkDarwinHost ./darwin/mbp)
    ];

    # NOTE: the following configuration currently do not work because HM fails
    # on news.json.output attribute missing (only available in standalone HM?).
    homeConfigurations = mkConfigurations [
      (mkHomeFromNixosHost "heimdall")
      (mkHomeFromNixosHost "linode")
      (mkHomeFromNixosHost "nyx")
      (mkHomeFromNixosHost "helios")
      (mkHomeFromNixosHost "selene")
      (mkHomeFromNixosHost "skullkid")
    ];

    nixosConfigurations = mkConfigurations [
      (mkNixosIso ./iso/recovery)
      (mkNixosIso ./iso/recovery-linode)
      (mkNixosIso ./iso/recovery-thunderbolt)

      (mkNixosHost ./nixos/heimdall)
      (mkNixosHost ./nixos/linode)
      (mkNixosHost ./nixos/nyx)
      (mkNixosHost ./nixos/helios)
      (mkNixosHost ./nixos/selene)
      (mkNixosHost ./nixos/skullkid)
    ];
  };
}
