{
  inputs,
  lib,
  ...
}: let
  inherit (inputs) self nix-darwin nixpkgs nixpkgs-darwin;
  inherit (self) usrlib;
  inherit (lib.attrsets) mapAttrs recursiveUpdate;
  inherit (lib.lists) singleton concatLists;
  inherit (lib.modules) mkDefault;

  # Merge `inputs` into `inputs'` in the shape expected by flake-parts such that:
  #
  # inputs =  { a = { x86_64-linux = {...}; }; b = { x86_64-linux = {...}; }; };
  # inputs' = { x = {...}; y = {...}; };
  #
  # mergeInputs' "x86_64-linux" inputs' inputs =
  #   { a = {...}; b = {...}; x = {...}; y = {...}; };
  mergeInputs' = system: inputs': inputs: let
    systemMappedInputs = mapAttrs (name: value: inputs.${system}.${name}) inputs;
  in
    recursiveUpdate inputs' systemMappedInputs;

  # mkSystem is a convenience wrapper around either lib.nixosSystem or
  # lib.darwinSystem.
  mkSystem = nixpkgs: systemBuilder: {
    withSystem,
    system,
    hostname,
    ...
  } @ args:
    withSystem system ({
      inputs',
      self',
      pkgs,
      ...
    }:
      systemBuilder {
        # Arguments passed to all modules.
        specialArgs = recursiveUpdate {
          inherit lib usrlib;
          inherit self';

          inputs = recursiveUpdate inputs (args.inputs or {});
          inputs' = mergeInputs' system inputs' (args.inputs or {});
          pkgs' = import inputs.nixpkgs-unstable {
            inherit system;
            inherit (pkgs) config overlays;
          };
          self = recursiveUpdate self (args.self or {});
        } (args.specialArgs or {});

        # Module list.
        modules = concatLists [
          (singleton {
            networking.hostName = hostname;
            nixpkgs.hostPlatform = mkDefault system;
          })

          # Additional modules passed to the host.
          (args.modules or [])
        ];
      });

  mkStandaloneHome = {
    withSystem,
    system,
    ...
  } @ args:
    withSystem system ({
      inputs',
      self',
      pkgs,
      ...
    }:
      inputs.home-manager.lib.homeManagerConfiguration {
        # Arguments passed to all modules.
        extraSpecialArgs = recursiveUpdate {
          inherit self' lib usrlib;

          inputs = recursiveUpdate inputs (args.inputs or {});
          inputs' = mergeInputs' system inputs' (args.inputs or {});
          pkgs' = import inputs.nixpkgs-unstable {
            inherit system;
            inherit (pkgs) config overlays;
          };
          self = recursiveUpdate self (args.self or {});
        } (args.extraSpecialArgs or {});

        # Explicit `pkgs` argument for standalone home-manager installs.
        pkgs = inputs'.nixpkgs.legacyPackages;

        # Module list.
        modules = args.modules or [];
      });

  mkDarwinSystem = mkSystem nixpkgs-darwin nix-darwin.lib.darwinSystem;
  mkNixosSystem = mkSystem nixpkgs nixpkgs.lib.nixosSystem;
in {
  inherit mkDarwinSystem mkNixosSystem mkStandaloneHome;
}
