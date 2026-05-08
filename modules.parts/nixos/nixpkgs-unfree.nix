{
  flake.nixosModules.nixpkgs-unfree = {
    nixpkgs.config.allowUnfree = true;
  };
}
