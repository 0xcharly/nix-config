{ inputs, ... }: {
  flake.homeModules.services-nix-index = {
    imports = [ inputs.nix-index-database.homeModules.default ];

    programs.nix-index-database.comma.enable = true;
  };
}
