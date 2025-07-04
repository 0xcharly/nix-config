{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;

  usrlib = {
    bool = import ./bool.nix;
    builders = import ./builders.nix {inherit inputs lib;};
    ghostty = import ./ghostty.nix {inherit lib;};
    hm = import ./hm.nix;
    modules = import ./modules.nix {inherit lib;};
    ssh = import ./ssh.nix {inherit lib;};
  };
in {
  perSystem = {
    # Set the `usrlib` arg of the flake as the extended lib.
    _module.args = {inherit usrlib;};
  };

  # Also set `usrlib` as a flake output, which allows for it to be referenced
  # outside the scope of this flake.
  flake = {inherit usrlib;};
}
