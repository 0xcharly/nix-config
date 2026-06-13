{
  flake.nixosModules.environment-man-less = {
    documentation = {
      enable = false;
      man.enable = false;
      nixos.enable = false;
    };
  };
}
