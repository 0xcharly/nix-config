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

  # Hardware compat for specific hardware, e.g. Raspberry Pi.
  hw = inputs.nixos-hardware.nixosModules;
  raspberrySdImage = "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-raspberrypi.nix";

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
    age = inputs.agenix.darwinModules.default; # Age darwin module.
    hm = inputs.home-manager.darwinModules.home-manager; # home-manager darwin module
  in
    mkHost (args'
      // {
        inherit host system;
        builder = mkDarwinSystem;
        moduleTrees = moduleTrees ++ [config managed shared users];
        roles = roles ++ [darwin];
        extraModules = extraModules ++ [age hm];
      });

  mkHomeHost = host: {
    system,
    username ? "delay",
    moduleTrees ? [],
    roles ? [],
    extraModules ? [],
    ...
  } @ args': let
    age = inputs.agenix.homeManagerModules.default; # Age HM module.
  in
    mkHost (args'
      // {
        inherit host system;
        builder = mkStandaloneHome;
        moduleTrees = moduleTrees ++ [config shared];
        roles = roles ++ [home];
        extraModules = extraModules ++ [age (import standalone username)];
      });

  mkNixosHost = host: {
    system,
    moduleTrees ? [],
    roles ? [],
    extraModules ? [],
    ...
  } @ args': let
    age = inputs.agenix.nixosModules.default; # Age nixos module.
    hm = inputs.home-manager.nixosModules.home-manager; # home-manager nixos module
  in
    mkHost (args'
      // {
        inherit host system;
        builder = mkNixosSystem;
        moduleTrees = moduleTrees ++ [config managed shared users];
        roles = roles ++ [nixos];
        extraModules = extraModules ++ [age hm];
      });

  mkNixosIso = host: {
    system,
    moduleTrees ? [],
    roles ? [],
    extraModules ? [],
    ...
  } @ args': let
    hm = inputs.home-manager.nixosModules.home-manager; # home-manager nixos module

    # Modules used to create a NixOS image.
    isoModule = {
      lib,
      modulesPath,
      ...
    }: {
      # TODO: move these into a proper role.
      services.openssh.settings.PermitRootLogin = lib.mkForce "yes";
      imports = [
        # Base ISO content.
        (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
        # Provide an initial copy of the NixOS channel so that the user
        # doesn't need to run "nix-channel --update" first.
        (modulesPath + "/installer/cd-dvd/channel.nix")
      ];
    };
  in
    mkHost (args'
      // {
        inherit host system;
        builder = mkNixosSystem;
        moduleTrees = moduleTrees ++ [config managed shared users];
        roles = roles ++ [nixos];
        extraModules = extraModules ++ [hm isoModule];
      });

  mkHostAttrs = builtins.foldl' recursiveUpdate {};
in rec {
  flake.lib = {
    inherit mkDarwinHost mkHomeHost mkNixosHost mkHostAttrs;
  };

  flake.darwinConfigurations = mkHostAttrs [
    (mkDarwinHost ./darwin/mbp {})
    (mkDarwinHost ./darwin/studio {})
  ];

  flake.homeConfigurations = let
    host = hostname: ./home + "/delay@${hostname}";
  in
    mkHostAttrs [
      (mkHomeHost (host "linode") {system = "x86_64-linux";})
      (mkHomeHost (host "pi4") {system = "aarch64-linux";})
      (mkHomeHost (host "pi5") {system = "aarch64-linux";})
    ];

  flake.nixosConfigurations = mkHostAttrs [
    (mkNixosIso ./iso/arm64 {system = "aarch64-linux";})
    (mkNixosIso ./iso/x64 {system = "x86_64-linux";})

    (mkNixosHost ./nixos/asl {system = "aarch64-linux";})
    (mkNixosHost ./nixos/vm-aarch64 {system = "aarch64-linux";})
    (mkNixosHost ./nixos/linode {system = "x86_64-linux";})
    (mkNixosHost ./nixos/nyx {system = "x86_64-linux";})
    (mkNixosHost ./nixos/rpi4 {
      system = "aarch64-linux";
      extraModules = [raspberrySdImage hw.raspberry-pi-4];
    })
    (mkNixosHost ./nixos/rpi5 {
      system = "aarch64-linux";
      extraModules = [raspberrySdImage hw.raspberry-pi-5];
    })
  ];

  flake.images = builtins.listToAttrs ((builtins.map (name: {
      inherit name;
      value = flake.nixosConfigurations."${name}".config.system.build.isoImage;
    }) ["arm64" "x64"])
    ++ (builtins.map (name: {
      inherit name;
      value = flake.nixosConfigurations."${name}".config.system.build.sdImage;
    }) ["rpi4" "rpi5"]));
}
