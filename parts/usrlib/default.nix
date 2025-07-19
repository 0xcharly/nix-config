{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;

  usrlib = {
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
