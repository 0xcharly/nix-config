{
  inputs,
  lib,
  stdenv,
  ...
}: let
  inherit (inputs) self nixpkgs;
  inherit (lib.attrsets) recursiveUpdate;
  inherit (lib.lists) singleton concatLists;
  inherit (lib.modules) mkDefault;
  inherit (stdenv) isDarwin;

  # mkSystem is a convenient wrapper around either lib.nixosSystem or
  # lib.darwinSystem.
  mkSystem = {
    withSystem,
    system,
    hostname,
    ...
  } @ args: let
    systemBuilder =
      if isDarwin
      then lib.darwinSystem
      else lib.nixosSystem;
  in
    withSystem system ({
      inputs',
      self',
      ...
    }:
      systemBuilder {
        # Arguments passed to all modules.
        specialArgs = recursiveUpdate {
          inherit (self) keys;
          inherit lib;
          inherit inputs self inputs' self';
        } (args.specialArgs or {});

        # Module list.
        modules = concatLists [
          (singleton {
            networking.hostName = args.hostname;
            nixpkgs = {
              hostPlatform = mkDefault args.system;
              flake.source = nixpkgs.outPath;
            };
          })

          # Additional modules passed to the host.
          (args.modules or [])
        ];
      });
in {
  inherit mkSystem;
}
