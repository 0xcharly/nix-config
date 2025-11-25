{inputs, ...}: {pkgs, ...}: {
  _module.args.pkgs' = import inputs.nixpkgs-stable {
    inherit (pkgs) system;
    config.allowUnfree = true;
  };
}
