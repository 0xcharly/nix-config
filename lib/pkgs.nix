inputs: {
  mkUnstablePkgs = pkgs:
    import inputs.nixpkgs-unstable {
      inherit (pkgs) config overlays system;
    };
}
