{inputs, ...}: {
  perSystem = {
    config,
    system,
    ...
  }: {
    # Configure nixpkgs locally and expose it as <flakeRef>.legacyPackages. This
    # will then be consumed to override flake-parts' pkgs argument to make
    # sure pkgs instances in flake-parts modules are all referring to the same
    # configuration instance - this one.
    legacyPackages = import inputs.nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
        allowUnsupportedSystem = true;
      };

      overlays = [inputs.self.overlays.default];
    };

    _module.args = {
      # Unify all instances of nixpkgs into a single `pkgs` set that includes
      # our own overlays within `perSystem`. This is not done by flake-parts,
      # so we do it ourselves.
      pkgs = config.legacyPackages;
    };
  };
}
