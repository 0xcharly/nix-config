{
  perSystem = {
    self',
    inputs',
    pkgs,
    system,
    ...
  }: let
    hooks-pkgs = inputs'.pre-commit-hooks.packages.${system};
  in {
    devShells.default =
      pkgs.mkShell
      {
        # Nix tools.
        nativeBuildInputs =
          (with hooks-pkgs; [
            alejandra
            markdownlint-cli
          ])
          ++ (with pkgs; [
            nixd
          ]);
        inherit (self'.checks.${system}.pre-commit-check) shellHook;
      };
    checks.pre-commit-check = inputs'.pre-commit-hooks.lib.${system}.run {
      src = self';
      hooks = {
        alejandra.enable = true;
        markdownlint = {
          enable = true;
          settings.configuration.MD034 = false;
        };
      };
    };
  };
}
