{
  flake.darwinModules.nixpkgs-unfree = {
    nixpkgs.config.allowUnfree = true;
  };
}
