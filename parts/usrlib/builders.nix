{
  inputs,
  lib,
  ...
}: let
  inherit (inputs) self nix-darwin nixpkgs nixpkgs-darwin;
  inherit (self) usrlib;
  inherit (lib.attrsets) recursiveUpdate;
  inherit (lib.lists) singleton concatLists;
  inherit (lib.modules) mkDefault;

  # mkSystem is a convenient wrapper around either lib.nixosSystem or
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
      ...
    }:
      systemBuilder {
        # Arguments passed to all modules.
        specialArgs = recursiveUpdate {
          inherit lib usrlib;
          inherit inputs self inputs' self';
        } (args.specialArgs or {});

        # Module list.
        modules = concatLists [
          (singleton {
            networking.hostName = args.hostname;
            nixpkgs = {
              hostPlatform = mkDefault args.system;
              # TODO: flake.source = nixpkgs.outPath;
            };
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
      ...
    }:
      inputs.home-manager.lib.homeManagerConfiguration {
        # Arguments passed to all modules.
        extraSpecialArgs = recursiveUpdate {
          inherit lib usrlib;
          inherit inputs self inputs' self';
        } (args.extraSpecialArgs or {});

        # Module list.
        modules = args.modules or [];
      });

  mkDarwinSystem = mkSystem nixpkgs-darwin nix-darwin.lib.darwinSystem;
  mkNixosSystem = mkSystem nixpkgs nixpkgs.lib.nixosSystem;
in {
  inherit mkDarwinSystem mkNixosSystem mkStandaloneHome;
}
