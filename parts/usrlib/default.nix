{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;

  usrlib = {
    builders = import ./builders.nix {inherit inputs lib;};
    modules = import ./modules.nix {inherit lib;};
  };
in {
  perSystem = {
    # Set the `usrlib` arg of the flake as the extended lib.
    _module.args = {inherit usrlib;};
  };

  flake = {
    # Also set `lib` as a flake output, which allows for it to be referenced outside
    # the scope of this flake.
    lib = usrlib;
  };
}
